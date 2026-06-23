--  Border (D1) shared types. Ada here is the GATE only: it screens messages
--  crossing toward the Brain. It deliberately does NOT model organs (those are
--  R / Octave / Pony / Guile), the inference cycle (cognition), or drive/affect
--  math (the organs' domain, done in floats). The gate needs exactly three
--  things: a source/trust tag, a status code, and a bounded payload to scan.
package Mafiabot_Types
  with SPARK_Mode => On
is

   --  Source / trust tag. The border screens by this: external-origin content
   --  is never trusted; System_Internal bypasses the blocklist. A message may
   --  not reclassify its own provenance (see Trust_Boundary.Validate_Provenance).
   type Provenance_Tag is (
      User_Input,
      System_Internal,
      LLM_Output,
      Tool_Result,
      Memory_Recall,
      Config_Static
   );

   --  Return status (replaces exceptions under the No_Exceptions profile).
   type Operation_Status is (
      OK,
      Error_Invalid_State,
      Error_Overflow,
      Error_Underflow,
      Error_Blocked,          --  screened out: injection pattern hit
      Error_Trust_Violation,  --  provenance reclassification attempt
      Error_Config
   );

   --  Payload buffer. By the time content reaches the border it has already
   --  been pre-digested upstream into bounded RAG context, so a stack-bounded
   --  buffer is the right shape: the gate scans it for prompt-injection
   --  patterns, it does not stream raw input. No heap, no finalization.
   Max_Text_Length : constant := 4096;
   subtype Text_Length is Natural range 0 .. Max_Text_Length;

   type Bounded_Text is record
      Data   : String (1 .. Max_Text_Length) := (others => ' ');
      Length : Text_Length := 0;
   end record;

   --  Helpers
   function Make_Text (S : String) return Bounded_Text
     with Pre => S'Length <= Max_Text_Length;

   function To_String (T : Bounded_Text) return String;

end Mafiabot_Types;
