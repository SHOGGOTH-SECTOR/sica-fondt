package body Soul.State
  with SPARK_Mode => On
is

   function Make_Session_Key
     (Uid     : String;
      Channel : String;
      Server  : String) return Bounded_Text
   is
      function D (S : String) return String is
        (if S'Length = 0 then "default" else S);
      Composed : constant String :=
        D (Uid) & "|" & D (Channel) & "|" & D (Server);
   begin
      if Composed'Length <= Max_Text_Length then
         return Make_Text (Composed);
      else
         return Make_Text
           (Composed (Composed'First .. Composed'First + Max_Text_Length - 1));
      end if;
   end Make_Session_Key;

   protected body Soul_State is

      --  ---- internal helpers ------------------------------------------

      function Keys_Equal (K : Session_Key; B : Bounded_Text) return Boolean is
         Eff : constant Natural :=
           (if B.Length <= Max_Key then B.Length else Max_Key);
      begin
         return K.Length = Eff
           and then K.Data (1 .. Eff) = B.Data (1 .. Eff);
      end Keys_Equal;

      procedure Set_Key (K : out Session_Key; B : Bounded_Text) is
         Eff : constant Natural :=
           (if B.Length <= Max_Key then B.Length else Max_Key);
      begin
         K.Data   := (others => ' ');
         K.Length := Eff;
         if Eff > 0 then
            K.Data (1 .. Eff) := B.Data (1 .. Eff);
         end if;
      end Set_Key;

      --  ---- identity --------------------------------------------------

      procedure Initialize_Big_Three
        (B3     : in  Soul.Tarot.Big_Three;
         Status : out Operation_Status)
      is
      begin
         if Initialized then
            Status := Error_Already_Init;
            return;
         end if;
         if not Soul.Tarot.Big_Three_Distinct (B3) then
            Status := Error_Config;
            return;
         end if;
         Big_3       := B3;
         Initialized := True;
         Status      := OK;
      end Initialize_Big_Three;

      --  ---- sessions --------------------------------------------------

      procedure Open_Session
        (Key    : in  Bounded_Text;
         Ref    : out Session_Ref;
         Status : out Operation_Status)
      is
         Free          : Session_Ref := No_Session;
         Remove_Status : Operation_Status;
      begin
         Ref := No_Session;

         for I in Valid_Session loop
            if Sessions (I).In_Use then
               if Keys_Equal (Sessions (I).Key, Key) then
                  Ref    := I;
                  Status := OK;
                  return;
               end if;
            elsif Free = No_Session then
               Free := I;
            end if;
         end loop;

         if Free = No_Session then
            Status := Error_Overflow;
            return;
         end if;

         --  Allocate a fresh session: full deck minus the immutable Big-3.
         Set_Key (Sessions (Free).Key, Key);
         Sessions (Free).Deck := Soul.Tarot.Full_Deck;
         Soul.Tarot.Remove_Big_Three
           (Sessions (Free).Deck, Big_3, Remove_Status);
         if Remove_Status /= OK then
            Status := Remove_Status;
            return;  --  slot left free (In_Use still False)
         end if;
         Sessions (Free).Spread         := Soul.Celtic_Cross.Empty_Spread;
         Sessions (Free).Layer_Done     := (others => False);
         Sessions (Free).Output_Counter := 0;
         Sessions (Free).In_Use         := True;
         Ref    := Free;
         Status := OK;
      end Open_Session;

      procedure Form_Layer
        (Ref    : in  Valid_Session;
         Layer  : in  Soul.Celtic_Cross.CC_Layer;
         Status : out Operation_Status)
      is
      begin
         --  Idempotent: a layer already drawn this session is held, not redrawn.
         if Sessions (Ref).Layer_Done (Layer) then
            Status := OK;
            return;
         end if;
         Soul.Celtic_Cross.Draw_Layer
           (Sessions (Ref).Deck, Sessions (Ref).Spread, Layer, Status);
         if Status = OK then
            Sessions (Ref).Layer_Done (Layer) := True;
         end if;
      end Form_Layer;

      procedure Reset_Spread (Ref : in Valid_Session) is
      begin
         Sessions (Ref).Spread     := Soul.Celtic_Cross.Empty_Spread;
         Sessions (Ref).Layer_Done := (others => False);
      end Reset_Spread;

      procedure Note_Output (Ref : in Valid_Session) is
      begin
         if Sessions (Ref).Output_Counter < Natural'Last then
            Sessions (Ref).Output_Counter := Sessions (Ref).Output_Counter + 1;
         end if;
      end Note_Output;

      --  ---- SOUL.md ---------------------------------------------------

      procedure Generate_Soul_MD
        (Buffer : out Bounded_Text;
         Status : out Operation_Status)
      is
         Sun_T  : constant Bounded_Text :=
           Soul.Celtic_Cross.Card_Token (Big_3.Sun);
         Moon_T : constant Bounded_Text :=
           Soul.Celtic_Cross.Card_Token (Big_3.Moon);
         Asc_T  : constant Bounded_Text :=
           Soul.Celtic_Cross.Card_Token (Big_3.Ascendant);

         Header : constant String := "# SOUL" & ASCII.LF;
         Sun_L  : constant String := "## Sun: ";
         Moon_L : constant String := ASCII.LF & "## Moon: ";
         Asc_L  : constant String := ASCII.LF & "## Ascendant: ";
         Footer : constant String := (1 => ASCII.LF);

         Total : constant Natural :=
           Header'Length
           + Sun_L'Length + Sun_T.Length
           + Moon_L'Length + Moon_T.Length
           + Asc_L'Length + Asc_T.Length
           + Footer'Length;
      begin
         Buffer := (Data => (others => ' '), Length => 0);
         if Total > Max_Text_Length then
            Status := Error_Overflow;
            return;
         end if;
         declare
            P : Natural := 1;
         begin
            Buffer.Data (P .. P + Header'Length - 1) := Header;   P := P + Header'Length;
            Buffer.Data (P .. P + Sun_L'Length - 1)  := Sun_L;    P := P + Sun_L'Length;
            Buffer.Data (P .. P + Sun_T.Length - 1)  := Sun_T.Data (1 .. Sun_T.Length);
                                                                    P := P + Sun_T.Length;
            Buffer.Data (P .. P + Moon_L'Length - 1) := Moon_L;   P := P + Moon_L'Length;
            Buffer.Data (P .. P + Moon_T.Length - 1) := Moon_T.Data (1 .. Moon_T.Length);
                                                                    P := P + Moon_T.Length;
            Buffer.Data (P .. P + Asc_L'Length - 1)  := Asc_L;    P := P + Asc_L'Length;
            Buffer.Data (P .. P + Asc_T.Length - 1)  := Asc_T.Data (1 .. Asc_T.Length);
                                                                    P := P + Asc_T.Length;
            Buffer.Data (P .. P + Footer'Length - 1) := Footer;
         end;
         Buffer.Length := Total;
         Status := OK;
      end Generate_Soul_MD;

      --  ---- accessors -------------------------------------------------

      function Is_Initialized return Boolean is (Initialized);

      function Get_Big_Three return Soul.Tarot.Big_Three is (Big_3);

      function Is_Spread_Formed (Ref : Valid_Session) return Boolean is
        (for all L in Soul.Celtic_Cross.CC_Layer => Sessions (Ref).Layer_Done (L));

      function Current_Spread (Ref : Valid_Session)
        return Soul.Celtic_Cross.CC_Spread is (Sessions (Ref).Spread);

      function Output_Count (Ref : Valid_Session) return Natural is
        (Sessions (Ref).Output_Counter);

      function Session_Count return Natural is
         N : Natural := 0;
      begin
         for I in Valid_Session loop
            if Sessions (I).In_Use then
               N := N + 1;
            end if;
         end loop;
         return N;
      end Session_Count;

   end Soul_State;

end Soul.State;
