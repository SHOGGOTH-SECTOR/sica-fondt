pragma SPARK_Mode (Off);  --  test harness uses Ada.Text_IO
with Ada.Text_IO; use Ada.Text_IO;
with Soul.Tarot;
with Soul.Celtic_Cross;
with Mafiabot_Types; use Mafiabot_Types;

procedure Soul_Tests is
   Fails : Natural := 0;

   procedure Check (Name : String; Cond : Boolean) is
   begin
      if Cond then
         Put_Line ("PASS " & Name);
      else
         Put_Line ("FAIL " & Name);
         Fails := Fails + 1;
      end if;
   end Check;

   B3 : constant Soul.Tarot.Big_Three :=
     (Sun       => (Kind => Soul.Tarot.Major, Major_Value => Soul.Tarot.The_Sun),
      Moon      => (Kind => Soul.Tarot.Major, Major_Value => Soul.Tarot.The_Moon),
      Ascendant => (Kind => Soul.Tarot.Major,
                    Major_Value => Soul.Tarot.SD_Singularity));

   D  : Soul.Tarot.Deck := Soul.Tarot.Full_Deck;
   St : Operation_Status;
begin
   Check ("full deck = 56", Soul.Tarot.Present_Count (D) = 56);
   Check ("big-3 distinct", Soul.Tarot.Big_Three_Distinct (B3));

   Soul.Tarot.Remove_Big_Three (D, B3, St);
   Check ("remove big-3 ok", St = OK);
   Check ("pool = 53", Soul.Tarot.Present_Count (D) = 53);

   --  The cross accretes layer by layer (2 + 2 + 2 + stave of 4).
   declare
      Sp : Soul.Celtic_Cross.CC_Spread := Soul.Celtic_Cross.Empty_Spread;
      L1, L2, L3, Lv : Operation_Status;
   begin
      Check ("empty spread has no Present slot",
             Sp (Soul.Celtic_Cross.Present).State = Soul.Tarot.Absent);

      Soul.Celtic_Cross.Draw_Layer (D, Sp, Soul.Celtic_Cross.Layer_1, L1);
      Check ("layer 1 ok", L1 = OK);
      Check ("pool = 51 after layer 1", Soul.Tarot.Present_Count (D) = 51);
      Check ("Present filled",
             Sp (Soul.Celtic_Cross.Present).State = Soul.Tarot.Present);
      Check ("Challenge filled",
             Sp (Soul.Celtic_Cross.Challenge).State = Soul.Tarot.Present);
      Check ("Outcome still empty",
             Sp (Soul.Celtic_Cross.Outcome).State = Soul.Tarot.Absent);

      Soul.Celtic_Cross.Draw_Layer (D, Sp, Soul.Celtic_Cross.Layer_2, L2);
      Soul.Celtic_Cross.Draw_Layer (D, Sp, Soul.Celtic_Cross.Layer_3, L3);
      Soul.Celtic_Cross.Draw_Layer (D, Sp, Soul.Celtic_Cross.Stave, Lv);
      Check ("layers 2/3/stave ok", L2 = OK and then L3 = OK and then Lv = OK);
      Check ("pool = 43 after full cross", Soul.Tarot.Present_Count (D) = 43);
      Check ("Outcome filled after stave",
             Sp (Soul.Celtic_Cross.Outcome).State = Soul.Tarot.Present);
   end;

   if Fails = 0 then
      Put_Line ("ALL SOUL TESTS PASSED");
   else
      Put_Line ("SOUL FAILURES:" & Natural'Image (Fails));
   end if;
end Soul_Tests;
