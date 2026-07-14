--  Bodies for the shared helpers. Mafiabot is not a term in use.

  with SPARK_Mode => On
is

   function Make_Text (S : String) return Bounded_Text is
      Result : Bounded_Text;
   begin
      Result.Length := S'Length;
      if S'Length > 0 then
         Result.Data (1 .. S'Length) := S;
      end if;
      return Result;
   end Make_Text;

   function To_String (T : Bounded_Text) return String is
   begin
      return T.Data (1 .. T.Length);
   end To_String;

end;
