--  Celtic Cross spread — 10-position layout mapped to inference cycle steps.
--
--  Position → Inference step:
--    Present, Challenge               → Step 6  (CC_Cards_1_2)
--    Foundation, Recent_Past          → Step 9  (CC_Cards_3_4)
--    Crown, Near_Future               → Step 13 (CC_Cards_5_6)
--    Self_Attitude..Outcome (4 cards) → Step 17 (CC_Cards_7_10)
--
--  Cards apply iteratively: each draw stays in the accumulation context for
--  all subsequent llmCog passes in the same inference cycle.
with Soul.Tarot;
with Mafiabot_Types; use Mafiabot_Types;

package Soul.Celtic_Cross
  with SPARK_Mode => On
is

   type CC_Position is (
      Present,
      Challenge,
      Foundation,
      Recent_Past,
      Crown,
      Near_Future,
      Self_Attitude,
      Environment,
      Hopes_Fears,
      Outcome
   );

   type CC_Spread is array (CC_Position) of Soul.Tarot.Deck_Slot;

   --  An empty (all-Absent) spread — the starting point before the cross
   --  accretes through the cognitive loops.
   function Empty_Spread return CC_Spread;

   --  The cross does not arrive whole. It accretes 2 cards per cognitive
   --  layer across the 4x4 metacognitive multicycle, then the stave (the
   --  4-card staff) is pulled as a block once the loops complete:
   --    Layer_1 (after wMC1/eMC1, step 6)  -> Present, Challenge
   --    Layer_2 (after wMC2/eMC2, step 9)  -> Foundation, Recent_Past
   --    Layer_3 (after wMC3/eMC3, step 13) -> Crown, Near_Future
   --    Stave   (after wMC4/eMC4, step 17) -> Self_Attitude .. Outcome
   type CC_Layer is (Layer_1, Layer_2, Layer_3, Stave);

   --  Number of card positions a given layer fills.
   function Cards_In_Layer (L : CC_Layer) return Positive is
     (if L = Stave then 4 else 2);

   --  Draw one layer's cards from the dynamic deck into the spread.
   --  Cards already present in the spread are left untouched. Removes the
   --  drawn cards from D. Returns Error_Deck_Empty if the deck cannot
   --  supply the layer.
   procedure Draw_Layer
     (D      : in out Soul.Tarot.Deck;
      Spread : in out CC_Spread;
      Layer  : in     CC_Layer;
      Status :    out Operation_Status)
   with Post => (if Status = OK then
                   Soul.Tarot.Present_Count (D) =
                     Soul.Tarot.Present_Count (D'Old) - Cards_In_Layer (Layer));

   --  Draw all ten cards at once from the dynamic deck (removes them from D).
   --  Convenience wrapper used by tests; the live cycle uses Draw_Layer.
   --  If fewer than 10 cards are present, returns Error_Deck_Empty.
   procedure Draw_Spread
     (D      : in out Soul.Tarot.Deck;
      Spread :    out CC_Spread;
      Status :    out Operation_Status)
   with Post => (if Status = OK then
                   Soul.Tarot.Present_Count (D) =
                     Soul.Tarot.Present_Count (D'Old) - 10);

   --  Card names as short Bounded_Text tokens for prompt injection.
   function Card_Token (C : Soul.Tarot.Card) return Bounded_Text;

   --  Serialise the spread slice for a given step into a Bounded_Text
   --  that can be injected into the metacognitive context.
   function Step_6_Context  (S : CC_Spread) return Bounded_Text;
   function Step_9_Context  (S : CC_Spread) return Bounded_Text;
   function Step_13_Context (S : CC_Spread) return Bounded_Text;
   function Step_17_Context (S : CC_Spread) return Bounded_Text;

end Soul.Celtic_Cross;
