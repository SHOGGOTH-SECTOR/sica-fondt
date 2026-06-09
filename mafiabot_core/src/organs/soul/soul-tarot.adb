package body Soul.Tarot
  with SPARK_Mode => On
is

   function Cards_Equal (A, B : Card) return Boolean is
   begin
      if A.Kind /= B.Kind then
         return False;
      end if;
      case A.Kind is
         when Major     => return A.Major_Value = B.Major_Value;
         when Court     => return A.Suit_Value = B.Suit_Value
                             and then A.Rank_Value = B.Rank_Value;
         when Void_Suit => return A.Void_Value = B.Void_Value;
      end case;
   end Cards_Equal;

   function Big_Three_Distinct (B3 : Big_Three) return Boolean is
   begin
      return not Cards_Equal (B3.Sun, B3.Moon)
        and then not Cards_Equal (B3.Sun, B3.Ascendant)
        and then not Cards_Equal (B3.Moon, B3.Ascendant);
   end Big_Three_Distinct;

   function Full_Deck return Deck is
      D : Deck;
   begin
      for I in Deck_Index loop
         D (I) := (State => Present, Value => Full_Alphabet (Alphabet_Index (I)));
      end loop;
      return D;
   end Full_Deck;

   procedure Remove_Big_Three
     (D      : in out Deck;
      B3     : in     Big_Three;
      Status :    out Operation_Status)
   is
      Removed : Natural := 0;
   begin
      for I in Deck_Index loop
         if D (I).State = Present then
            if Cards_Equal (D (I).Value, B3.Sun)
              or else Cards_Equal (D (I).Value, B3.Moon)
              or else Cards_Equal (D (I).Value, B3.Ascendant)
            then
               D (I).State := Absent;
               Removed := Removed + 1;
            end if;
         end if;
      end loop;
      if Removed = 3 then
         Status := OK;
      else
         Status := Error_Config;  --  Big-3 cards not found in deck
      end if;
   end Remove_Big_Three;

   function Present_Count (D : Deck) return Natural is
      Count : Natural := 0;
   begin
      for I in Deck_Index loop
         if D (I).State = Present then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Present_Count;

end Soul.Tarot;
