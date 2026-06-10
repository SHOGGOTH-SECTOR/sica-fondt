pragma SPARK_Mode (Off);  --  test harness uses Ada.Text_IO
with Ada.Text_IO; use Ada.Text_IO;
with Soul.Tarot;
with Soul.State;
with Ada_Medium;
with Mafiabot_Types; use Mafiabot_Types;

procedure Cycle_Tests is
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

   St : Operation_Status;
begin
   Soul.State.Soul_State.Initialize_Big_Three (B3, St);
   Check ("identity init ok", St = OK);

   declare
      R : Operation_Status;
   begin
      Soul.State.Soul_State.Initialize_Big_Three (B3, R);
      Check ("double init rejected", R = Error_Already_Init);
   end;

   --  Session A: full cycle forms and holds the cross.
   declare
      Key  : constant Bounded_Text :=
        Soul.State.Make_Session_Key ("alice", "telegram", "srv1");
      Out1 : Bounded_Text;
      Ref  : Soul.State.Session_Ref;
      R    : Operation_Status;
   begin
      Ada_Medium.Run_Inference_Cycle (Key, Make_Text ("hello"), Out1, R);
      Check ("session A cycle ok", R = OK);
      Check ("session A output non-empty", Out1.Length > 0);

      Soul.State.Soul_State.Open_Session (Key, Ref, R);
      Check ("session A reopen ok", R = OK and then Ref in Soul.State.Valid_Session);
      Check ("session A cross formed",
             Soul.State.Soul_State.Is_Spread_Formed (Ref));
      Check ("session A output count = 1",
             Soul.State.Soul_State.Output_Count (Ref) = 1);
   end;

   --  Session A again: cross is HELD (already formed), counter advances.
   declare
      Key  : constant Bounded_Text :=
        Soul.State.Make_Session_Key ("alice", "telegram", "srv1");
      Out2 : Bounded_Text;
      Ref  : Soul.State.Session_Ref;
      R    : Operation_Status;
   begin
      Ada_Medium.Run_Inference_Cycle (Key, Make_Text ("again"), Out2, R);
      Check ("session A second cycle ok", R = OK);
      Soul.State.Soul_State.Open_Session (Key, Ref, R);
      Check ("session A output count = 2",
             Soul.State.Soul_State.Output_Count (Ref) = 2);
   end;

   --  Session B: a different (uid, channel, server) is fully independent.
   declare
      Key  : constant Bounded_Text :=
        Soul.State.Make_Session_Key ("bob", "discord", "srv2");
      Out3 : Bounded_Text;
      Ref  : Soul.State.Session_Ref;
      R    : Operation_Status;
   begin
      Ada_Medium.Run_Inference_Cycle (Key, Make_Text ("hi"), Out3, R);
      Check ("session B cycle ok", R = OK);
      Soul.State.Soul_State.Open_Session (Key, Ref, R);
      Check ("session B output count = 1",
             Soul.State.Soul_State.Output_Count (Ref) = 1);
   end;

   Check ("two live sessions", Soul.State.Soul_State.Session_Count = 2);

   if Fails = 0 then
      Put_Line ("ALL CYCLE TESTS PASSED");
   else
      Put_Line ("CYCLE FAILURES:" & Natural'Image (Fails));
   end if;
end Cycle_Tests;
