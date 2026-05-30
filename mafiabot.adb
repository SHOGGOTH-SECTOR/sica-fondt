pragma Profile (Jorvik);
pragma SPARK_Mode (Off);  --  Main procedure: orchestrates I/O-facing init.

with Bot_Config;
with Engine;

procedure Mafiabot is
   Config   : Bot_Config.Bot_Configuration;
   Registry : Engine.Daemon_Registry;
begin
   null;
end Mafiabot;
