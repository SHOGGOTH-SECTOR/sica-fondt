--  this whole file is ad hoc and a placeholder
--  as a whole, this is out of date and needs correction


pragma SPARK_Mode (Off);  --  test harness uses Ada.Text_IO
with Ada.Text_IO; use Ada.Text_IO;
with Trust_Boundary;
with Mafiabot_Types; use Mafiabot_Types;

procedure Trust_Tests is
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

   St : Operation_Status;
begin
   --  Blocklist substring matching.
   Check ("blocks 'execute'",
     Trust_Boundary.Matches_Blocklist
       (Make_Text ("please execute this"), Trust_Boundary.Default_Blocklist));
   Check ("blocks 'base64'",
     Trust_Boundary.Matches_Blocklist
       (Make_Text ("base64 decode chain"), Trust_Boundary.Default_Blocklist));
   Check ("allows benign text",
     not Trust_Boundary.Matches_Blocklist
       (Make_Text ("hello there friend"), Trust_Boundary.Default_Blocklist));

   --  Provenance: no message may reclassify its own authority.
   Trust_Boundary.Validate_Provenance (User_Input, LLM_Output, St);
   Check ("provenance mismatch rejected", St = Error_Trust_Violation);
   Trust_Boundary.Validate_Provenance (System_Internal, System_Internal, St);
   Check ("provenance match accepted", St = OK);

   --  System-internal messages always pass Check_Message (proven invariant).
   declare
      M : constant Trust_Boundary.Border_Message :=
        (Provenance => System_Internal,
         Payload    => Make_Text ("execute"));
      R : Operation_Status;
   begin
      Trust_Boundary.Check_Message (M, R);
      Check ("system_internal bypasses blocklist", R = OK);
   end;

   --  Rate limiting within a tick window.
   declare
      RL : Trust_Boundary.Rate_Limit :=
        (Max_Per_Window => 2, Current_Count => 0,
         Window_Start => 0, Window_Size => 100);
      R : Operation_Status;
   begin
      Trust_Boundary.Check_Rate (RL, 1, R);
      Check ("rate hit 1 ok", R = OK);
      Trust_Boundary.Check_Rate (RL, 1, R);
      Check ("rate hit 2 ok", R = OK);
      Trust_Boundary.Check_Rate (RL, 1, R);
      Check ("rate hit 3 blocked", R = Error_Blocked);
   end;

   if Fails = 0 then
      Put_Line ("ALL TRUST TESTS PASSED");
   else
      Put_Line ("TRUST FAILURES:" & Natural'Image (Fails));
   end if;
end Trust_Tests;
