package body Config_Loader
  with SPARK_Mode => On
is

   --  Skip leading/trailing ASCII spaces and tabs in a substring.
   procedure Trim_Bounds
     (S     : in     String;
      First : in out Positive;
      Last  : in out Natural)
   with Pre => S'First <= First and then Last <= S'Last;

   procedure Trim_Bounds
     (S     : in     String;
      First : in out Positive;
      Last  : in out Natural)
   is
   begin
      while First <= Last and then (S (First) = ' ' or else S (First) = ASCII.HT) loop
         First := First + 1;
      end loop;
      while Last >= First and then (S (Last) = ' ' or else S (Last) = ASCII.HT) loop
         Last := Last - 1;
      end loop;
   end Trim_Bounds;

   procedure Load_From_Buffer
     (Buf    : in     String;
      Store  :    out Config_Store;
      Status :    out Operation_Status)
   is
      Line_Start : Positive := Buf'First;
      I          : Positive;
      Line_End   : Natural;
      Colon_Pos  : Natural;
      K_First    : Positive;
      K_Last     : Natural;
      V_First    : Positive;
      V_Last     : Natural;
      Key_Len    : Key_Length;
      Val_Len    : Val_Length;
   begin
      Store  := (Count => 0,
                 Entries => (others => (Key => (others => ' '), Key_Len => 0,
                                        Val => (others => ' '), Val_Len => 0)));
      Status := OK;

      I := Buf'First;
      while I <= Buf'Last loop
         --  Find end of current line
         Line_Start := I;
         Line_End   := I - 1;
         while I <= Buf'Last and then Buf (I) /= ASCII.LF loop
            Line_End := I;
            I := I + 1;
         end loop;
         --  Consume newline
         if I <= Buf'Last and then Buf (I) = ASCII.LF then
            I := I + 1;
         end if;

         --  Skip blank lines and comments
         K_First := Line_Start;
         K_Last  := Line_End;
         Trim_Bounds (Buf, K_First, K_Last);
         if K_First > K_Last
           or else Buf (K_First) = '#'
         then
            goto Next_Line;
         end if;

         --  Find colon separator
         Colon_Pos := 0;
         for J in K_First .. K_Last loop
            if Buf (J) = ':' then
               Colon_Pos := J;
               exit;
            end if;
         end loop;

         if Colon_Pos = 0 then
            goto Next_Line;  --  no colon: not a key-value line, skip
         end if;

         --  Key span
         K_First := Line_Start;
         K_Last  := Colon_Pos - 1;
         Trim_Bounds (Buf, K_First, K_Last);

         --  Value span
         V_First := Colon_Pos + 1;
         V_Last  := Line_End;
         if V_First <= V_Last then
            Trim_Bounds (Buf, V_First, V_Last);
         end if;

         --  Validate lengths
         if K_Last < K_First then
            goto Next_Line;
         end if;

         Key_Len := K_Last - K_First + 1;
         if Key_Len > Max_Key_Len then
            Status := Error_Config;
            return;
         end if;

         if V_Last >= V_First then
            Val_Len := V_Last - V_First + 1;
         else
            Val_Len := 0;
         end if;
         if Val_Len > Max_Val_Len then
            Status := Error_Config;
            return;
         end if;

         --  Check store capacity
         if Store.Count = Max_Keys then
            Status := Error_Overflow;
            return;
         end if;

         Store.Count := Store.Count + 1;
         declare
            Idx : constant Entry_Index := Entry_Index (Store.Count);
         begin
            Store.Entries (Idx).Key_Len := Key_Len;
            Store.Entries (Idx).Key (1 .. Key_Len) :=
              Buf (K_First .. K_Last);
            Store.Entries (Idx).Val_Len := Val_Len;
            if Val_Len > 0 then
               Store.Entries (Idx).Val (1 .. Val_Len) :=
                 Buf (V_First .. V_Last);
            end if;
         end;

         <<Next_Line>>
         null;
      end loop;
   end Load_From_Buffer;

   function Get_Value
     (Store : Config_Store;
      Key   : String) return Bounded_Text
   is
      Result : Bounded_Text;
   begin
      for I in 1 .. Store.Count loop
         declare
            E : constant Config_Entry := Store.Entries (Entry_Index (I));
         begin
            if E.Key_Len = Key'Length
              and then E.Key (1 .. E.Key_Len) = Key
            then
               Result.Length := E.Val_Len;
               Result.Data (1 .. E.Val_Len) := E.Val (1 .. E.Val_Len);
               return Result;
            end if;
         end;
      end loop;
      return Result;
   end Get_Value;

end Config_Loader;
