--  Silicon Dawn Tarot encoding alphabet — 56-card identity system.
--  Thoth/Golden-Dawn rooted; Silicon Dawn (Egypt Urnash) retitlings applied.
--
--  Alphabet breakdown:
--    31 Major Arcana  (25 standard + 6 Silicon Dawn unique)
--    20 Court/99      (4 suits × 5 positions: 99, King, Queen, Chevalier, P)
--     5 (VOID) suit   (Queen, King, Chevalier, Progeny, 0)
--    ──────────────
--    56 total
--
--  Numbered minors (Ace–10) are in the deck but outside the encoding alphabet.
with Mafiabot_Types; use Mafiabot_Types;

package Soul.Tarot
  with SPARK_Mode => On
is

   --  -----------------------------------------------------------------------
   --  Major Arcana — 31 cards

   type Major_Arcana is (
      --  Standard 22 (0–XXI), Thoth-aligned titles
      The_Fool,           --  0
      The_Magician,       --  I
      The_High_Priestess, --  II
      The_Empress,        --  III
      The_Emperor,        --  IV
      The_Hierophant,     --  V
      The_Lovers,         --  VI
      The_Chariot,        --  VII
      Adjustment,         --  VIII  (Thoth: Adjustment = Justice)
      The_Hermit,         --  IX
      Fortune,            --  X     (Thoth: Fortune = Wheel)
      Lust,               --  XI    (Thoth: Lust = Strength)
      The_Hanged_Man,     --  XII
      Death,              --  XIII
      Art,                --  XIV   (Thoth: Art = Temperance)
      The_Devil,          --  XV
      The_Tower,          --  XVI
      The_Star,           --  XVII
      The_Moon,           --  XVIII
      The_Sun,            --  XIX
      The_Aeon,           --  XX    (Thoth: Aeon = Judgement)
      The_Universe,       --  XXI   (Thoth: Universe = World)
      --  Silicon Dawn additions — 9 unique cards
      SD_Maya,            --  8.5    (between VIII and IX)
      SD_History,         --  SD unique
      SD_Virus,           --  SD unique
      SD_Achievement,     --  SD unique
      SD_Digital,         --  SD unique
      SD_Vulture_Mother,  --  SD retitling of Death position (kept as alias)
      SD_She_Is_Legend,   --  SD retitling of Adjustment
      SD_Schrodinger,     --  SD unique
      SD_Singularity      --  SD unique
   );

   --  -----------------------------------------------------------------------
   --  Standard suits — court tier per suit: 99 > King > Queen > Chevalier > P

   type Suit is (Wands, Cups, Swords, Pentacles);

   --  P slot is Princess or Prince, gendered OPPOSITE to the element's gender.
   --  (Silicon Dawn swapped mapping: Pentacles=Fire, Wands=Earth.)
   type Court_Rank is (Ninety_Nine, King, Queen, Chevalier, P);

   --  -----------------------------------------------------------------------
   --  (VOID) suit — 5 cards: Queen > King > Chevalier > Progeny > Zero

   type Void_Card is (Void_Queen, Void_King, Void_Chevalier, Void_Progeny,
                      Void_Zero);

   --  -----------------------------------------------------------------------
   --  Unified card discriminated record

   type Card_Kind is (Major, Court, Void_Suit);

   type Card (Kind : Card_Kind := Major) is record
      case Kind is
         when Major     => Major_Value : Major_Arcana := The_Fool;
         when Court     => Suit_Value  : Suit := Wands;
                           Rank_Value  : Court_Rank := Ninety_Nine;
         when Void_Suit => Void_Value  : Void_Card := Void_Zero;
      end case;
   end record;

   --  -----------------------------------------------------------------------
   --  Full 56-card encoding alphabet

   Total_Alphabet : constant := 56;
   type Alphabet_Index is range 1 .. Total_Alphabet;
   type Alphabet is array (Alphabet_Index) of Card;

   --  The canonical alphabet (built at elaboration time)
   Full_Alphabet : constant Alphabet;

   --  -----------------------------------------------------------------------
   --  Big-Three — immutable personality anchors (Sun / Moon / Ascendant)

   type Big_Three is record
      Sun       : Card;
      Moon      : Card;
      Ascendant : Card;
   end record;

   --  Validate that three cards are distinct (Big-3 must not repeat)
   function Big_Three_Distinct (B3 : Big_Three) return Boolean;

   --  -----------------------------------------------------------------------
   --  Working deck — 56 slots; entries may be "absent" (flagged by a sentinel)

   type Slot_State is (Present, Absent);

   type Deck_Slot is record
      State : Slot_State := Absent;
      Value : Card;
   end record;

   type Deck_Index is range 1 .. Total_Alphabet;
   type Deck is array (Deck_Index) of Deck_Slot;

   --  Build a full, ordered deck from the canonical alphabet
   function Full_Deck return Deck;

   --  Remove the three Big-3 cards from a deck (returns dynamic 53-card pool)
   procedure Remove_Big_Three
     (D      : in out Deck;
      B3     : in     Big_Three;
      Status :    out Operation_Status);

   --  Count present cards
   function Present_Count (D : Deck) return Natural;

private

   --  Build the canonical 56-card alphabet at compile time.
   --  Order: 31 Majors, then 20 Court (suit-major order), then 5 VOID.
   Full_Alphabet : constant Alphabet :=
     (
      --  Majors 1..31
      1  => (Kind => Major, Major_Value => The_Fool),
      2  => (Kind => Major, Major_Value => The_Magician),
      3  => (Kind => Major, Major_Value => The_High_Priestess),
      4  => (Kind => Major, Major_Value => The_Empress),
      5  => (Kind => Major, Major_Value => The_Emperor),
      6  => (Kind => Major, Major_Value => The_Hierophant),
      7  => (Kind => Major, Major_Value => The_Lovers),
      8  => (Kind => Major, Major_Value => The_Chariot),
      9  => (Kind => Major, Major_Value => Adjustment),
      10 => (Kind => Major, Major_Value => The_Hermit),
      11 => (Kind => Major, Major_Value => Fortune),
      12 => (Kind => Major, Major_Value => Lust),
      13 => (Kind => Major, Major_Value => The_Hanged_Man),
      14 => (Kind => Major, Major_Value => Death),
      15 => (Kind => Major, Major_Value => Art),
      16 => (Kind => Major, Major_Value => The_Devil),
      17 => (Kind => Major, Major_Value => The_Tower),
      18 => (Kind => Major, Major_Value => The_Star),
      19 => (Kind => Major, Major_Value => The_Moon),
      20 => (Kind => Major, Major_Value => The_Sun),
      21 => (Kind => Major, Major_Value => The_Aeon),
      22 => (Kind => Major, Major_Value => The_Universe),
      23 => (Kind => Major, Major_Value => SD_Maya),
      24 => (Kind => Major, Major_Value => SD_History),
      25 => (Kind => Major, Major_Value => SD_Virus),
      26 => (Kind => Major, Major_Value => SD_Achievement),
      27 => (Kind => Major, Major_Value => SD_Digital),
      28 => (Kind => Major, Major_Value => SD_Vulture_Mother),
      29 => (Kind => Major, Major_Value => SD_She_Is_Legend),
      30 => (Kind => Major, Major_Value => SD_Schrodinger),
      31 => (Kind => Major, Major_Value => SD_Singularity),
      --  Court cards 32..51 (Wands, Cups, Swords, Pentacles × 5 ranks)
      32 => (Kind => Court, Suit_Value => Wands,     Rank_Value => Ninety_Nine),
      33 => (Kind => Court, Suit_Value => Wands,     Rank_Value => King),
      34 => (Kind => Court, Suit_Value => Wands,     Rank_Value => Queen),
      35 => (Kind => Court, Suit_Value => Wands,     Rank_Value => Chevalier),
      36 => (Kind => Court, Suit_Value => Wands,     Rank_Value => P),
      37 => (Kind => Court, Suit_Value => Cups,      Rank_Value => Ninety_Nine),
      38 => (Kind => Court, Suit_Value => Cups,      Rank_Value => King),
      39 => (Kind => Court, Suit_Value => Cups,      Rank_Value => Queen),
      40 => (Kind => Court, Suit_Value => Cups,      Rank_Value => Chevalier),
      41 => (Kind => Court, Suit_Value => Cups,      Rank_Value => P),
      42 => (Kind => Court, Suit_Value => Swords,    Rank_Value => Ninety_Nine),
      43 => (Kind => Court, Suit_Value => Swords,    Rank_Value => King),
      44 => (Kind => Court, Suit_Value => Swords,    Rank_Value => Queen),
      45 => (Kind => Court, Suit_Value => Swords,    Rank_Value => Chevalier),
      46 => (Kind => Court, Suit_Value => Swords,    Rank_Value => P),
      47 => (Kind => Court, Suit_Value => Pentacles, Rank_Value => Ninety_Nine),
      48 => (Kind => Court, Suit_Value => Pentacles, Rank_Value => King),
      49 => (Kind => Court, Suit_Value => Pentacles, Rank_Value => Queen),
      50 => (Kind => Court, Suit_Value => Pentacles, Rank_Value => Chevalier),
      51 => (Kind => Court, Suit_Value => Pentacles, Rank_Value => P),
      --  VOID 52..56
      52 => (Kind => Void_Suit, Void_Value => Void_Queen),
      53 => (Kind => Void_Suit, Void_Value => Void_King),
      54 => (Kind => Void_Suit, Void_Value => Void_Chevalier),
      55 => (Kind => Void_Suit, Void_Value => Void_Progeny),
      56 => (Kind => Void_Suit, Void_Value => Void_Zero)
     );

end Soul.Tarot;
