--  this whole file is ad hoc and a placeholder
--  as a whole, this is out of date and needs correction


pragma SPARK_Mode (Off);  --  test harness uses Ada.Text_IO
with Ada.Text_IO; use Ada.Text_IO;
   if Fails = 0 then
      Put_Line ("ALL TRUST TESTS PASSED");
   else
      Put_Line ("TRUST FAILURES:" & Natural'Image (Fails));
   end if;
end Trust_Tests;
