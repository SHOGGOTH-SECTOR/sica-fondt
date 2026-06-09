--  NullClaw / AI Mafia Bot Gen.03 — MCP stdio server entry point.
--
--  Speaks JSON-RPC over stdin/stdout so the Hermes Agent harness can mount it
--  as an `mcp_servers` entry. On start it fixes the global Big-3 identity and
--  writes ~/.hermes/SOUL.md, then serves: initialize, tools/list, tools/call.
--  Each tools/call runs the 23-step organ-systems inference cycle, scoped to a
--  session keyed by (uid, channel, server) drawn from the call arguments.
--
--  SPARK_Mode Off: the driver performs I/O and orchestration only — it calls
--  into the SPARK-proven organs (Ada_Medium, Soul.State, Trust_Boundary) and
--  the SPARK_Mode-Off protocol bridge. No proof obligations live here.
pragma SPARK_Mode (Off);
with Mafiabot_Types; use Mafiabot_Types;
with Soul.Tarot;
with Soul.State;
with Ada_Medium;
with Hermes_Protocol;

procedure Mafiabot is

   --  Default identity anchors (three distinct Majors). A config-driven Big-3
   --  is a follow-up item; these give a stable, valid starting identity.
   Default_Big_Three : constant Soul.Tarot.Big_Three :=
     (Sun       => (Kind => Soul.Tarot.Major, Major_Value => Soul.Tarot.The_Sun),
      Moon      => (Kind => Soul.Tarot.Major, Major_Value => Soul.Tarot.The_Moon),
      Ascendant => (Kind => Soul.Tarot.Major,
                    Major_Value => Soul.Tarot.SD_Singularity));

   procedure Compare (A : Bounded_Text; B : String; Equal : out Boolean) is
   begin
      Equal := A.Length = B'Length
        and then A.Data (1 .. A.Length) = B;
   end Compare;

   Status   : Operation_Status;
   Soul_Buf : Bounded_Text;

begin
   --  --- Organ init: fix identity, publish SOUL.md ---------------------
   Soul.State.Soul_State.Initialize_Big_Three (Default_Big_Three, Status);
   if Status /= OK then
      return;  --  cannot run without a valid identity
   end if;

   Soul.State.Soul_State.Generate_Soul_MD (Soul_Buf, Status);
   if Status = OK then
      Hermes_Protocol.Write_Soul_MD (Soul_Buf, Status);
      --  A failed SOUL.md write is non-fatal: Hermes can still call tools.
   end if;

   --  --- MCP serve loop ------------------------------------------------
   loop
      declare
         In_Buf     : Hermes_Protocol.JSON_Buffer;
         Out_Buf    : Hermes_Protocol.JSON_Buffer;
         Read_St    : Operation_Status;
         Id         : Bounded_Text;
         Method     : Bounded_Text;
         Is_Init    : Boolean;
         Is_List    : Boolean;
         Is_Call    : Boolean;
         Is_Notif   : Boolean;
      begin
         Hermes_Protocol.Read_Message (In_Buf, Read_St);
         exit when Read_St /= OK;          --  stdin closed -> shut down

         if In_Buf.Length > 0 then         --  skip blank lines
            Hermes_Protocol.Extract_Raw_Field (In_Buf, "id", Id);
            Hermes_Protocol.Extract_Field (In_Buf, "method", Method);

            Compare (Method, "initialize", Is_Init);
            Compare (Method, "tools/list", Is_List);
            Compare (Method, "tools/call", Is_Call);
            Compare (Method, "notifications/initialized", Is_Notif);

            if Is_Init then
               Hermes_Protocol.Make_Init_Response (Id, Out_Buf);
               Hermes_Protocol.Write_Message (Out_Buf);

            elsif Is_List then
               Hermes_Protocol.Make_Tools_List_Response (Id, Out_Buf);
               Hermes_Protocol.Write_Message (Out_Buf);

            elsif Is_Call then
               declare
                  Input_Txt : Bounded_Text;
                  Uid_Txt   : Bounded_Text;
                  Chan_Txt  : Bounded_Text;
                  Srv_Txt   : Bounded_Text;
                  Key       : Bounded_Text;
                  Result    : Bounded_Text;
                  Cyc_St    : Operation_Status;
               begin
                  Hermes_Protocol.Extract_Field (In_Buf, "input",   Input_Txt);
                  Hermes_Protocol.Extract_Field (In_Buf, "uid",     Uid_Txt);
                  Hermes_Protocol.Extract_Field (In_Buf, "channel", Chan_Txt);
                  Hermes_Protocol.Extract_Field (In_Buf, "server",  Srv_Txt);

                  if Input_Txt.Length = 0 then
                     Hermes_Protocol.Make_Error_Response
                       (Id, -32602, "missing 'input' argument", Out_Buf);
                  else
                     Key := Soul.State.Make_Session_Key
                       (To_String (Uid_Txt),
                        To_String (Chan_Txt),
                        To_String (Srv_Txt));
                     Ada_Medium.Run_Inference_Cycle
                       (Key, Input_Txt, Result, Cyc_St);
                     if Cyc_St = OK then
                        Hermes_Protocol.Make_Tool_Result_Response
                          (Id, Result, Out_Buf);
                     else
                        Hermes_Protocol.Make_Error_Response
                          (Id, -32000, "inference cycle failed", Out_Buf);
                     end if;
                  end if;
                  Hermes_Protocol.Write_Message (Out_Buf);
               end;

            elsif Is_Notif then
               null;  --  notifications take no response

            else
               Hermes_Protocol.Make_Error_Response
                 (Id, -32601, "method not found", Out_Buf);
               Hermes_Protocol.Write_Message (Out_Buf);
            end if;
         end if;
      end;
   end loop;
end Mafiabot;
