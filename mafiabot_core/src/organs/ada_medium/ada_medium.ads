--  Ada Connective Medium — the organ-systems body's shared medium.
--  NOT a controller; organs are perfused BY it, not subordinated TO it.
--
--  Defines:
--    - Organ_Message (inter-organ communication)
--    - Inference_Phase enum (23-step cycle)
--    - Inference_Orchestrator protected object
--    - Run_Inference_Cycle — the top-level 23-step pipeline
with Mafiabot_Types;   use Mafiabot_Types;
with Trust_Boundary;
with Soul.Celtic_Cross;
with System;

package Ada_Medium
  with SPARK_Mode => On
is

   --  Re-export Organ_Message from Trust_Boundary for callers
   subtype Organ_Message is Trust_Boundary.Organ_Message;

   --  ML toolchain interface descriptors (capability flags, not live handles)
   type ML_Tool is (LoRA_Adapter, SAE_Steering, BERT_Classifier, RAG_Retrieval);

   type Tool_Descriptor is record
      Tool    : ML_Tool;
      Enabled : Boolean := False;
   end record;

   type ML_Toolkit is array (ML_Tool) of Tool_Descriptor;

   --  -----------------------------------------------------------------------
   --  Inference cycle: 23 steps

   type Inference_Phase is (
      Phase_Input,          --  1  INPUT received
      Phase_Enrich,         --  2  Ada enriches (drive state + RAG context)
      Phase_LLM_Init,       --  3  LLM init.thoughtChain
      Phase_WMC1,           --  4  wMC1 Socratic destabilisation
      Phase_EMC1,           --  5  eMC1 Iranian Asha/Daena alignment
      Phase_CC_1_2,         --  6  CC cards 1 & 2 injected
      Phase_WMC2,           --  7  wMC2 Kantian boundary mapping
      Phase_EMC2,           --  8  eMC2 East Asian Xin-Zhai mirror
      Phase_CC_3_4,         --  9  CC cards 3 & 4 injected
      Phase_LLM_Cog_1,      -- 10  first llmCog
      Phase_WMC3,           -- 11  wMC3 Freud/Hegel depth
      Phase_EMC3,           -- 12  eMC3 Indic Sakshibhava witness
      Phase_CC_5_6,         -- 13  CC cards 5 & 6 injected
      Phase_LLM_Cog_2,      -- 14  second llmCog
      Phase_WMC4,           -- 15  wMC4 modern pragmatic stream
      Phase_EMC4,           -- 16  eMC4 Tibetan Bön elemental flow
      Phase_CC_7_10,        -- 17  CC cards 7–10 injected
      Phase_Final_Cog,      -- 18  finalLLMcog
      Phase_Mini_Rag,       -- 19  mini-rag JIT schema lookup
      Phase_Send_Ada,       -- 20  sendAda
      Phase_Route,          -- 21  Ada routes to tools
      Phase_Synthesize,     -- 22  Synthesize
      Phase_Coherence       -- 23  Coherence check / drift detection
   );

   --  -----------------------------------------------------------------------
   --  Inference orchestrator — enforces forward-only phase progression.
   --  Illegal jumps yield Error_Invalid_State and halt the cycle.

   protected Inference_Orchestrator is
      pragma Priority (System.Priority'Last);

      procedure Advance
        (Next   : in  Inference_Phase;
         Status : out Operation_Status)
      with Post =>
        (if Status = OK then
           Get_Current = Next
         else
           Get_Current = Phase_Input);  --  reset on illegal jump

      function Get_Current return Inference_Phase;

      procedure Reset;

   private
      Current : Inference_Phase := Phase_Input;
   end Inference_Orchestrator;

   --  -----------------------------------------------------------------------
   --  Message routing through the trust boundary

   procedure Route_Message
     (Msg    : in  Organ_Message;
      Status : out Operation_Status)
   with Pre => Msg.Payload.Length > 0;

   --  -----------------------------------------------------------------------
   --  Top-level 23-step inference cycle.
   --
   --  Session_Key scopes the Celtic Cross and card pool to one (uid, channel,
   --  server) tuple — compose it with Soul.State.Make_Session_Key. Distinct
   --  sessions never share a deck or a cross; the Big-3 identity is global.

   procedure Run_Inference_Cycle
     (Session_Key : in  Bounded_Text;
      Input       : in  Bounded_Text;
      Output      : out Bounded_Text;
      Status      : out Operation_Status)
   with Pre => Input.Length > 0;

   --  Toolkit accessor (configured at startup)
   function Active_Toolkit return ML_Toolkit;
   procedure Configure_Tool (Tool : ML_Tool; Enabled : Boolean);

end Ada_Medium;
