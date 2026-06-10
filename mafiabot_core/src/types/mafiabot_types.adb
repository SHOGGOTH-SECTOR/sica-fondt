package body Mafiabot_Types
  with SPARK_Mode => On
is

   function Make_Text (S : String) return Bounded_Text is
      T : Bounded_Text;
      L : constant Text_Length := S'Length;
   begin
      T.Length := L;
      T.Data (1 .. L) := S;
      return T;
   end Make_Text;

   function To_String (T : Bounded_Text) return String is
   begin
      return T.Data (1 .. T.Length);
   end To_String;

end Mafiabot_Types;
