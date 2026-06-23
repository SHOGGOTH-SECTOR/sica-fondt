--  Hermes MCP stdio bridge body.
--  SPARK_Mode Off: Ada.Text_IO is not analysable by SPARK. All trust-boundary
--  screening happens in proven code (Ada_Medium / Trust_Boundary) before any
--  procedure here is called. The global No_Exceptions restriction still applies,
--  so I/O is written to avoid raising (End_Of_File guards, bounded Get_Line).
-- [we should probly reconsider this as the first layer then]
with Ada.Text_IO;
with Ada.Environment_Variables;

package body Hermes_Protocol
  with SPARK_Mode => Off
is

   --  -------------------------------------------------------------------
   --  Buffer append helpers (truncate silently at Max_JSON_Length)

   procedure Append (Buf : in out JSON_Buffer; S : in String) is
      Avail : constant Natural := Max_JSON_Length - Buf.Length;
      N     : constant Natural := (if S'Length <= Avail then S'Length else Avail);
   begin
      if N > 0 then
         Buf.Data (Buf.Length + 1 .. Buf.Length + N) :=
           S (S'First .. S'First + N - 1);
         Buf.Length := Buf.Length + N;
      end if;
   end Append;

   procedure Append (Buf : in out JSON_Buffer; T : in Bounded_Text) is
   begin
      Append (Buf, T.Data (1 .. T.Length));
   end Append;

   --  Append a string with the minimal JSON escaping needed for safety.
   procedure Append_Escaped (Buf : in out JSON_Buffer; S : in String) is
   begin
      for I in S'Range loop
         case S (I) is
            when '"'      => Append (Buf, "\""");
            when '\'      => Append (Buf, "\\");
            when ASCII.LF => Append (Buf, "\n");
            when ASCII.CR => Append (Buf, "\r");
            when ASCII.HT => Append (Buf, "\t");
            when others   => Append (Buf, String'(1 => S (I)));
         end case;
      end loop;
   end Append_Escaped;

   procedure Append_Escaped (Buf : in out JSON_Buffer; T : in Bounded_Text) is
   begin
      Append_Escaped (Buf, T.Data (1 .. T.Length));
   end Append_Escaped;

   --  -------------------------------------------------------------------

   procedure Read_Message
     (Buf    : out JSON_Buffer;
      Status : out Operation_Status)
   is
      use Ada.Text_IO;
      Line : String (1 .. Max_JSON_Length);
      Last : Natural;
   begin
      Buf := (Data => (others => ' '), Length => 0);
      --  Guard EOF so Get_Line cannot raise End_Error under No_Exceptions.
      if End_Of_File then
         Status := Error_Invalid_State;  --  stdin closed: caller shuts down
         return;
      end if;
      Get_Line (Line, Last);
      if Last > 0 then
         Buf.Data (1 .. Last) := Line (1 .. Last);
         Buf.Length := Last;
      end if;
      Status := OK;
   end Read_Message;

   procedure Write_Message (Buf : in JSON_Buffer) is
      use Ada.Text_IO;
   begin
      Put (Buf.Data (1 .. Buf.Length));
      New_Line;
      Flush;
   end Write_Message;

   --  -------------------------------------------------------------------
   --  Minimal `"key": "value"` extractor. Not a full JSON parser: it finds
   --  the first occurrence of the quoted key, the following colon, then the
   --  next quoted string, and copies that as the value.

   procedure Extract_Field
     (Buf   : in  JSON_Buffer;
      Key   : in  String;
      Value : out Bounded_Text)
   is
      Quoted : constant String := '"' & Key & '"';
      I      : Natural := 1;
      Found  : Natural := 0;
   begin
      Value := (Data => (others => ' '), Length => 0);
      if Quoted'Length = 0 or else Buf.Length < Quoted'Length then
         return;
      end if;

      --  Locate the key.
      while I <= Buf.Length - Quoted'Length + 1 loop
         if Buf.Data (I .. I + Quoted'Length - 1) = Quoted then
            Found := I + Quoted'Length;
            exit;
         end if;
         I := I + 1;
      end loop;
      if Found = 0 then
         return;
      end if;

      --  Skip whitespace and the colon.
      I := Found;
      while I <= Buf.Length
        and then (Buf.Data (I) = ' ' or else Buf.Data (I) = ':'
                  or else Buf.Data (I) = ASCII.HT)
      loop
         I := I + 1;
      end loop;

      --  Expect an opening quote.
      if I > Buf.Length or else Buf.Data (I) /= '"' then
         return;
      end if;
      I := I + 1;  --  first char of the value

      --  Copy until the closing quote (honouring backslash escapes minimally).
      while I <= Buf.Length and then Buf.Data (I) /= '"' loop
         if Buf.Data (I) = '\' and then I < Buf.Length then
            I := I + 1;  --  take the escaped char literally
         end if;
         if Value.Length < Max_Text_Length then
            Value.Length := Value.Length + 1;
            Value.Data (Value.Length) := Buf.Data (I);
         end if;
         I := I + 1;
      end loop;
   end Extract_Field;

   procedure Extract_Raw_Field
     (Buf   : in  JSON_Buffer;
      Key   : in  String;
      Value : out Bounded_Text)
   is
      Quoted : constant String := '"' & Key & '"';
      I      : Natural := 1;
      Found  : Natural := 0;
   begin
      Value := Make_Text ("null");
      if Quoted'Length = 0 or else Buf.Length < Quoted'Length then
         return;
      end if;

      while I <= Buf.Length - Quoted'Length + 1 loop
         if Buf.Data (I .. I + Quoted'Length - 1) = Quoted then
            Found := I + Quoted'Length;
            exit;
         end if;
         I := I + 1;
      end loop;
      if Found = 0 then
         return;
      end if;

      I := Found;
      while I <= Buf.Length
        and then (Buf.Data (I) = ' ' or else Buf.Data (I) = ':'
                  or else Buf.Data (I) = ASCII.HT)
      loop
         I := I + 1;
      end loop;
      if I > Buf.Length then
         return;
      end if;

      Value := (Data => (others => ' '), Length => 0);
      if Buf.Data (I) = '"' then
         --  Quoted string: copy through the closing quote, inclusive.
         Value.Length := 1;
         Value.Data (1) := '"';
         I := I + 1;
         while I <= Buf.Length and then Buf.Data (I) /= '"' loop
            if Buf.Data (I) = '\' and then I < Buf.Length then
               if Value.Length < Max_Text_Length then
                  Value.Length := Value.Length + 1;
                  Value.Data (Value.Length) := Buf.Data (I);
               end if;
               I := I + 1;
            end if;
            if Value.Length < Max_Text_Length then
               Value.Length := Value.Length + 1;
               Value.Data (Value.Length) := Buf.Data (I);
            end if;
            I := I + 1;
         end loop;
         if Value.Length < Max_Text_Length then
            Value.Length := Value.Length + 1;
            Value.Data (Value.Length) := '"';
         end if;
      else
         --  Bare token: copy until a structural delimiter.
         while I <= Buf.Length
           and then Buf.Data (I) /= ',' and then Buf.Data (I) /= '}'
           and then Buf.Data (I) /= ' ' and then Buf.Data (I) /= ASCII.HT
         loop
            if Value.Length < Max_Text_Length then
               Value.Length := Value.Length + 1;
               Value.Data (Value.Length) := Buf.Data (I);
            end if;
            I := I + 1;
         end loop;
      end if;

      if Value.Length = 0 then
         Value := Make_Text ("null");
      end if;
   end Extract_Raw_Field;

   --  -------------------------------------------------------------------

   procedure Write_Soul_MD
     (Content : in  Bounded_Text;
      Status  : out Operation_Status)
   is
      use Ada.Text_IO;
      F : File_Type;
   begin
      Status := Error_Config;
      if not Ada.Environment_Variables.Exists ("HOME") then
         return;
      end if;
      declare
         Home : constant String := Ada.Environment_Variables.Value ("HOME");
         Path : constant String := Home & "/.hermes/SOUL.md";
      begin
         --  Assumes ~/.hermes exists (Hermes owns that directory).
         Create (F, Out_File, Path);
         Put (F, Content.Data (1 .. Content.Length));
         Close (F);
         Status := OK;
      end;
   end Write_Soul_MD;

   --  -------------------------------------------------------------------
   --  JSON-RPC response builders

   procedure Make_Init_Response
     (Id  : in  Bounded_Text;
      Buf : out JSON_Buffer)
   is
   begin
      Buf := (Data => (others => ' '), Length => 0);
      Append (Buf, "{""jsonrpc"":""2.0"",""id"":");
      Append (Buf, Id);
      Append (Buf, ",""result"":{""protocolVersion"":""2024-11-05"",");
      Append (Buf, """capabilities"":{""tools"":{}},");
      Append (Buf,
        """serverInfo"":{""name"":""mafiabot_core"",""version"":""gen03""}}}");
   end Make_Init_Response;

   procedure Make_Tools_List_Response
     (Id  : in  Bounded_Text;
      Buf : out JSON_Buffer)
   is
   begin
      Buf := (Data => (others => ' '), Length => 0);
      Append (Buf, "{""jsonrpc"":""2.0"",""id"":");
      Append (Buf, Id);
      Append (Buf, ",""result"":{""tools"":[{""name"":""infer"",");
      Append (Buf,
        """description"":""Run the Gen.03 23-step organ-systems inference "
        & "cycle over an input and return the enriched cognition context."",");
      Append (Buf,
        """inputSchema"":{""type"":""object"",""properties"":"
        & "{""input"":{""type"":""string"",""description"":"
        & """The user message to reason over.""}},""required"":[""input""]}");
      Append (Buf, "}]}}");
   end Make_Tools_List_Response;

   procedure Make_Tool_Result_Response
     (Id     : in  Bounded_Text;
      Result : in  Bounded_Text;
      Buf    : out JSON_Buffer)
   is
   begin
      Buf := (Data => (others => ' '), Length => 0);
      Append (Buf, "{""jsonrpc"":""2.0"",""id"":");
      Append (Buf, Id);
      Append (Buf, ",""result"":{""content"":[{""type"":""text"",""text"":""");
      Append_Escaped (Buf, Result);
      Append (Buf, """}]}}");
   end Make_Tool_Result_Response;

   procedure Make_Error_Response
     (Id      : in  Bounded_Text;
      Code    : in  Integer;
      Message : in  String;
      Buf     : out JSON_Buffer)
   is
      Code_Img : constant String := Integer'Image (Code);
      --  Integer'Image leads with a space for non-negatives; strip it.
      Code_Str : constant String :=
        (if Code_Img'Length > 0 and then Code_Img (Code_Img'First) = ' '
         then Code_Img (Code_Img'First + 1 .. Code_Img'Last)
         else Code_Img);
   begin
      Buf := (Data => (others => ' '), Length => 0);
      Append (Buf, "{""jsonrpc"":""2.0"",""id"":");
      Append (Buf, Id);
      Append (Buf, ",""error"":{""code"":");
      Append (Buf, Code_Str);
      Append (Buf, ",""message"":""");
      Append_Escaped (Buf, Message);
      Append (Buf, """}}");
   end Make_Error_Response;

end Hermes_Protocol;
