pragma SPARK_Mode (Off);  --  test harness uses Ada.Text_IO
with Ada.Text_IO; use Ada.Text_IO;
with Config_Loader;
with Mafiabot_Types; use Mafiabot_Types;

procedure Config_Tests is
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

   Store : Config_Loader.Config_Store;
   St    : Operation_Status;

   Buf : constant String :=
     "# gen.03 config" & ASCII.LF &
     "host: localhost"  & ASCII.LF &
     "port: 8080"       & ASCII.LF &
     ""                 & ASCII.LF &
     "name: ada"        & ASCII.LF;
begin
   Config_Loader.Load_From_Buffer (Buf, Store, St);
   Check ("load ok", St = OK);
   Check ("count = 3", Store.Count = 3);

   declare
      V : constant Bounded_Text := Config_Loader.Get_Value (Store, "host");
   begin
      Check ("host = localhost", To_String (V) = "localhost");
   end;
   declare
      V : constant Bounded_Text := Config_Loader.Get_Value (Store, "port");
   begin
      Check ("port = 8080", To_String (V) = "8080");
   end;
   declare
      V : constant Bounded_Text := Config_Loader.Get_Value (Store, "missing");
   begin
      Check ("missing key empty", V.Length = 0);
   end;

   if Fails = 0 then
      Put_Line ("ALL CONFIG TESTS PASSED");
   else
      Put_Line ("CONFIG FAILURES:" & Natural'Image (Fails));
   end if;
end Config_Tests;
