--  Shared type definitions for the Gen.03 organ-systems body.
--  All downstream packages with Mafiabot_Types.
package Mafiabot_Types
  with SPARK_Mode => On
is

   --  Organ identification
   type Organ_Id is (Ada_Medium, Drive_Box, Soul_Organ, Mini_Rag, LLM_Cycle,
                     Trust_Layer, Protocol_Layer);

   --  Inference cycle steps: 23-step flow from INPUT to Coherence_Check
   type Cycle_Step is range 1 .. 23;

   --  Bounded string (stack-allocated; no heap, no finalization)
   Max_Text_Length : constant := 4096;
   subtype Text_Length is Natural range 0 .. Max_Text_Length;

   type Bounded_Text is record
      Data   : String (1 .. Max_Text_Length) := (others => ' ');
      Length : Text_Length := 0;
   end record;

   --  Return status (replaces exceptions under No_Exceptions profile)
   type Operation_Status is (
      OK,
      Error_Invalid_State,
      Error_Overflow,
      Error_Underflow,
      Error_Blocked,          --  tool-locked (energy below threshold)
      Error_Trust_Violation,
      Error_Config,
      Error_Already_Init,     --  Big-3 already set
      Error_Deck_Empty
   );

   --  Fixed-point numerics (SPARK-provable; no Float)
   type Drive_Value  is delta 0.001 range -100.0 .. 100.0;
   type Ratio_Value  is delta 0.001 range   0.0 ..   1.0;
   type Cost_Value   is delta 0.001 range   0.0 .. 1000.0;
   type Axis_Value   is delta 0.01  range  -1.0 ..   1.0;
   --  Pin 'Small to 0.01 so the bounds are +/-100 units (fits a byte) rather
   --  than GNAT's default 2**-7 small, which would place 1.0 at exactly 128 --
   --  one past a signed-8-bit base range and rejected as "high bound outside
   --  type range".
   for Axis_Value'Small use 0.01;

   --  Provenance tags — trust boundary uses these to block reclassification
   type Provenance_Tag is (
      User_Input,
      System_Internal,
      LLM_Output,
      Tool_Result,
      Memory_Recall,
      Config_Static
   );

   --  Helpers

   function Make_Text (S : String) return Bounded_Text
     with Pre => S'Length <= Max_Text_Length;

   function To_String (T : Bounded_Text) return String;

end Mafiabot_Types;
