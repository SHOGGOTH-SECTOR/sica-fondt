pragma Profile (Jorvik);
pragma SPARK_Mode (Off);  --  Test harness: Off; prove the units, not the runner.

with Engine;
with Economy;

procedure Engine_Tests is
   Registry : Engine.Daemon_Registry;
begin
   Engine.Initialize (Registry);
   pragma Assert (for all D in Engine.Daemon_Kind => Registry (D) = Engine.Stopped);
end Engine_Tests;
