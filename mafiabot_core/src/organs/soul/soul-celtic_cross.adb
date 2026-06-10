package body Soul.Celtic_Cross
  with SPARK_Mode => On
is

   procedure Draw_Spread
     (D      : in out Soul.Tarot.Deck;
      Spread :    out CC_Spread;
      Status :    out Operation_Status)
   is
      Drawn : Natural := 0;
      Pos   : CC_Position := CC_Position'First;
   begin
      Spread := (others => (State => Soul.Tarot.Absent,
                            Value => (Kind => Soul.Tarot.Major,
                                      Major_Value => Soul.Tarot.The_Fool)));

      if Soul.Tarot.Present_Count (D) < 10 then
         Status := Error_Deck_Empty;
         return;
      end if;

      for I in Soul.Tarot.Deck_Index loop
         exit when Drawn = 10;
         if D (I).State = Soul.Tarot.Present then
            Spread (Pos) := D (I);
            D (I).State  := Soul.Tarot.Absent;
            Drawn        := Drawn + 1;
            if Pos /= CC_Position'Last then
               Pos := CC_Position'Succ (Pos);
            end if;
         end if;
      end loop;

      Status := OK;
   end Draw_Spread;

   --  ------------------------------------------------------------------

   function Empty_Spread return CC_Spread is
   begin
      return (others => (State => Soul.Tarot.Absent,
                         Value => (Kind => Soul.Tarot.Major,
                                   Major_Value => Soul.Tarot.The_Fool)));
   end Empty_Spread;

   procedure Draw_Layer
     (D      : in out Soul.Tarot.Deck;
      Spread : in out CC_Spread;
      Layer  : in     CC_Layer;
      Status :    out Operation_Status)
   is
      Need    : constant Positive := Cards_In_Layer (Layer);
      Targets : array (1 .. 4) of CC_Position := (others => CC_Position'First);
      Count   : Natural := 0;
   begin
      case Layer is
         when Layer_1 =>
            Targets (1) := Present;       Targets (2) := Challenge;
         when Layer_2 =>
            Targets (1) := Foundation;    Targets (2) := Recent_Past;
         when Layer_3 =>
            Targets (1) := Crown;         Targets (2) := Near_Future;
         when Stave =>
            Targets (1) := Self_Attitude; Targets (2) := Environment;
            Targets (3) := Hopes_Fears;   Targets (4) := Outcome;
      end case;

      if Soul.Tarot.Present_Count (D) < Need then
         Status := Error_Deck_Empty;
         return;
      end if;

      for I in Soul.Tarot.Deck_Index loop
         exit when Count = Need;
         if D (I).State = Soul.Tarot.Present then
            Spread (Targets (Count + 1)) := D (I);
            D (I).State := Soul.Tarot.Absent;
            Count := Count + 1;
         end if;
      end loop;

      Status := OK;
   end Draw_Layer;

   --  ------------------------------------------------------------------
   --  Card token serialisation

   function Major_Token (M : Soul.Tarot.Major_Arcana) return String is
   begin
      case M is
         when Soul.Tarot.The_Fool           => return "THE_FOOL";
         when Soul.Tarot.The_Magician       => return "THE_MAGICIAN";
         when Soul.Tarot.The_High_Priestess => return "HIGH_PRIESTESS";
         when Soul.Tarot.The_Empress        => return "THE_EMPRESS";
         when Soul.Tarot.The_Emperor        => return "THE_EMPEROR";
         when Soul.Tarot.The_Hierophant     => return "THE_HIEROPHANT";
         when Soul.Tarot.The_Lovers         => return "THE_LOVERS";
         when Soul.Tarot.The_Chariot        => return "THE_CHARIOT";
         when Soul.Tarot.Adjustment         => return "ADJUSTMENT";
         when Soul.Tarot.The_Hermit         => return "THE_HERMIT";
         when Soul.Tarot.Fortune            => return "FORTUNE";
         when Soul.Tarot.Lust               => return "LUST";
         when Soul.Tarot.The_Hanged_Man     => return "THE_HANGED_MAN";
         when Soul.Tarot.Death              => return "DEATH";
         when Soul.Tarot.Art                => return "ART";
         when Soul.Tarot.The_Devil          => return "THE_DEVIL";
         when Soul.Tarot.The_Tower          => return "THE_TOWER";
         when Soul.Tarot.The_Star           => return "THE_STAR";
         when Soul.Tarot.The_Moon           => return "THE_MOON";
         when Soul.Tarot.The_Sun            => return "THE_SUN";
         when Soul.Tarot.The_Aeon           => return "THE_AEON";
         when Soul.Tarot.The_Universe       => return "THE_UNIVERSE";
         when Soul.Tarot.SD_Maya            => return "SD_MAYA";
         when Soul.Tarot.SD_History         => return "SD_HISTORY";
         when Soul.Tarot.SD_Virus           => return "SD_VIRUS";
         when Soul.Tarot.SD_Achievement     => return "SD_ACHIEVEMENT";
         when Soul.Tarot.SD_Digital         => return "SD_DIGITAL";
         when Soul.Tarot.SD_Vulture_Mother  => return "SD_VULTURE_MOTHER";
         when Soul.Tarot.SD_She_Is_Legend   => return "SD_SHE_IS_LEGEND";
         when Soul.Tarot.SD_Schrodinger     => return "SD_SCHRODINGER";
         when Soul.Tarot.SD_Singularity     => return "SD_SINGULARITY";
      end case;
   end Major_Token;

   function Suit_Token (S : Soul.Tarot.Suit) return String is
   begin
      case S is
         when Soul.Tarot.Wands     => return "WANDS";
         when Soul.Tarot.Cups      => return "CUPS";
         when Soul.Tarot.Swords    => return "SWORDS";
         when Soul.Tarot.Pentacles => return "PENTACLES";
      end case;
   end Suit_Token;

   function Rank_Token (R : Soul.Tarot.Court_Rank) return String is
   begin
      case R is
         when Soul.Tarot.Ninety_Nine => return "99";
         when Soul.Tarot.King        => return "KING";
         when Soul.Tarot.Queen       => return "QUEEN";
         when Soul.Tarot.Chevalier   => return "CHEVALIER";
         when Soul.Tarot.P           => return "P";
      end case;
   end Rank_Token;

   function Void_Token (V : Soul.Tarot.Void_Card) return String is
   begin
      case V is
         when Soul.Tarot.Void_Queen     => return "VOID_QUEEN";
         when Soul.Tarot.Void_King      => return "VOID_KING";
         when Soul.Tarot.Void_Chevalier => return "VOID_CHEVALIER";
         when Soul.Tarot.Void_Progeny   => return "VOID_PROGENY";
         when Soul.Tarot.Void_Zero      => return "VOID_ZERO";
      end case;
   end Void_Token;

   function Card_Token (C : Soul.Tarot.Card) return Bounded_Text is
      S : String (1 .. 64) := (others => ' ');
      L : Natural := 0;
   begin
      case C.Kind is
         when Soul.Tarot.Major =>
            declare
               T : constant String := Major_Token (C.Major_Value);
            begin
               L := T'Length;
               S (1 .. L) := T;
            end;
         when Soul.Tarot.Court =>
            declare
               R : constant String := Rank_Token (C.Rank_Value);
               U : constant String := Suit_Token (C.Suit_Value);
               Combined : constant String := R & "_OF_" & U;
            begin
               L := Combined'Length;
               if L <= 64 then
                  S (1 .. L) := Combined;
               end if;
            end;
         when Soul.Tarot.Void_Suit =>
            declare
               T : constant String := Void_Token (C.Void_Value);
            begin
               L := T'Length;
               S (1 .. L) := T;
            end;
      end case;
      declare
         Result : Bounded_Text;
      begin
         if L <= Max_Text_Length then
            Result.Length := L;
            Result.Data (1 .. L) := S (1 .. L);
         end if;
         return Result;
      end;
   end Card_Token;

   --  Build a two-card context string "[POS: TOKEN, POS: TOKEN]"
   function Two_Card_Context
     (P1 : CC_Position; C1 : Soul.Tarot.Deck_Slot;
      P2 : CC_Position; C2 : Soul.Tarot.Deck_Slot) return Bounded_Text
   is
      pragma Unreferenced (P1, P2);
      T1 : constant Bounded_Text :=
        (if C1.State = Soul.Tarot.Present then Card_Token (C1.Value)
         else Make_Text ("ABSENT"));
      T2 : constant Bounded_Text :=
        (if C2.State = Soul.Tarot.Present then Card_Token (C2.Value)
         else Make_Text ("ABSENT"));
      Prefix : constant String := "[CC:";
      Sep    : constant String := "|";
      Suffix : constant String := "]";
      Combined_Len : constant Natural :=
        Prefix'Length + T1.Length + Sep'Length + T2.Length + Suffix'Length;
      Result : Bounded_Text;
   begin
      if Combined_Len <= Max_Text_Length then
         Result.Length := Combined_Len;
         declare
            P : Natural := 1;
         begin
            Result.Data (P .. P + Prefix'Length - 1) := Prefix;
            P := P + Prefix'Length;
            Result.Data (P .. P + T1.Length - 1) := T1.Data (1 .. T1.Length);
            P := P + T1.Length;
            Result.Data (P .. P + Sep'Length - 1) := Sep;
            P := P + Sep'Length;
            Result.Data (P .. P + T2.Length - 1) := T2.Data (1 .. T2.Length);
            P := P + T2.Length;
            Result.Data (P .. P + Suffix'Length - 1) := Suffix;
         end;
      end if;
      return Result;
   end Two_Card_Context;

   function Step_6_Context (S : CC_Spread) return Bounded_Text is
   begin
      return Two_Card_Context (Present,    S (Present),
                               Challenge,  S (Challenge));
   end Step_6_Context;

   function Step_9_Context (S : CC_Spread) return Bounded_Text is
   begin
      return Two_Card_Context (Foundation,  S (Foundation),
                               Recent_Past, S (Recent_Past));
   end Step_9_Context;

   function Step_13_Context (S : CC_Spread) return Bounded_Text is
   begin
      return Two_Card_Context (Crown,       S (Crown),
                               Near_Future, S (Near_Future));
   end Step_13_Context;

   function Step_17_Context (S : CC_Spread) return Bounded_Text is
      --  Four cards — build as two concatenated two-card strings
      First  : constant Bounded_Text :=
        Two_Card_Context (Self_Attitude, S (Self_Attitude),
                          Environment,   S (Environment));
      Second : constant Bounded_Text :=
        Two_Card_Context (Hopes_Fears, S (Hopes_Fears),
                          Outcome,     S (Outcome));
      Sep : constant String := ";";
      Combined_Len : constant Natural :=
        First.Length + Sep'Length + Second.Length;
      Result : Bounded_Text;
   begin
      if Combined_Len <= Max_Text_Length then
         Result.Length := Combined_Len;
         Result.Data (1 .. First.Length) := First.Data (1 .. First.Length);
         Result.Data (First.Length + 1 .. First.Length + Sep'Length) := Sep;
         Result.Data (First.Length + Sep'Length + 1 .. Combined_Len) :=
           Second.Data (1 .. Second.Length);
      end if;
      return Result;
   end Step_17_Context;

end Soul.Celtic_Cross;
