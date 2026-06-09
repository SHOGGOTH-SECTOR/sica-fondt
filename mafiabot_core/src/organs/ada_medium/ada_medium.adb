with Soul.State;

package body Ada_Medium
  with SPARK_Mode => On
is

   --  Internal toolkit state
   Toolkit : ML_Toolkit :=
     (LoRA_Adapter    => (Tool => LoRA_Adapter,    Enabled => False),
      SAE_Steering    => (Tool => SAE_Steering,     Enabled => False),
      BERT_Classifier => (Tool => BERT_Classifier,  Enabled => False),
      RAG_Retrieval   => (Tool => RAG_Retrieval,    Enabled => False));

   --  -----------------------------------------------------------------------
   --  Phase transition table: only forward steps are legal.
   --  Phase_Input is the universal reset target.

   function Next_Legal (Current : Inference_Phase) return Inference_Phase is
   begin
      if Current = Phase_Coherence then
         return Phase_Input;  --  wrap after full cycle
      else
         return Inference_Phase'Succ (Current);
      end if;
   end Next_Legal;

   --  -----------------------------------------------------------------------

   protected body Inference_Orchestrator is

      procedure Advance
        (Next   : in  Inference_Phase;
         Status : out Operation_Status)
      is
      begin
         if Next = Next_Legal (Current) then
            Current := Next;
            Status  := OK;
         else
            --  Illegal jump: reset to Phase_Input
            Current := Phase_Input;
            Status  := Error_Invalid_State;
         end if;
      end Advance;

      function Get_Current return Inference_Phase is (Current);

      procedure Reset is
      begin
         Current := Phase_Input;
      end Reset;

   end Inference_Orchestrator;

   --  -----------------------------------------------------------------------

   procedure Route_Message
     (Msg    : in  Organ_Message;
      Status : out Operation_Status)
   is
   begin
      Trust_Boundary.Trust_Guard.Screen_Inbound (Msg, Status);
   end Route_Message;

   --  -----------------------------------------------------------------------
   --  Helpers that build organ messages for each cycle step

   function Make_Internal_Msg
     (Src  : Organ_Id;
      Dst  : Organ_Id;
      Text : Bounded_Text) return Organ_Message
   is
   begin
      return (Source      => Src,
              Destination => Dst,
              Provenance  => System_Internal,
              Payload     => Text);
   end Make_Internal_Msg;

   --  Build a metacognitive prompt envelope for a Western phase.
   function WMC_Envelope
     (Phase : Natural;
      Input : Bounded_Text) return Bounded_Text
   is
      Labels : constant array (1 .. 4) of String (1 .. 32) :=
        ("WMC1:SOCRATIC_APORIA            ",
         "WMC2:KANTIAN_BOUNDARIES         ",
         "WMC3:FREUD_HEGEL_DEPTH          ",
         "WMC4:MODERN_PRAGMATIC           ");
      Label_Len : constant := 24;
      Pfx  : constant String := "[";
      Sep  : constant String := "]";
      L    : constant String := Labels (Phase) (1 .. Label_Len);
      Env  : Bounded_Text;
      Len  : constant Natural := Pfx'Length + L'Length + Sep'Length + Input.Length;
   begin
      if Len <= Max_Text_Length then
         Env.Length := Len;
         declare
            P : Natural := 1;
         begin
            Env.Data (P .. P + Pfx'Length - 1) := Pfx;           P := P + Pfx'Length;
            Env.Data (P .. P + L'Length - 1)   := L;             P := P + L'Length;
            Env.Data (P .. P + Sep'Length - 1) := Sep;           P := P + Sep'Length;
            Env.Data (P .. P + Input.Length - 1) :=
              Input.Data (1 .. Input.Length);
         end;
      end if;
      return Env;
   end WMC_Envelope;

   --  Build a metacognitive prompt envelope for a Non-Western phase.
   function EMC_Envelope
     (Phase : Natural;
      Input : Bounded_Text) return Bounded_Text
   is
      Labels : constant array (1 .. 4) of String (1 .. 32) :=
        ("EMC1:IRANIAN_ASHA_DAENA         ",
         "EMC2:EAST_ASIAN_XIN_ZHAI        ",
         "EMC3:INDIC_SAKSHIBHAVA          ",
         "EMC4:TIBETAN_BON                ");
      Label_Len : constant := 24;
      Pfx  : constant String := "{";
      Sep  : constant String := "}";
      L    : constant String := Labels (Phase) (1 .. Label_Len);
      Env  : Bounded_Text;
      Len  : constant Natural := Pfx'Length + L'Length + Sep'Length + Input.Length;
   begin
      if Len <= Max_Text_Length then
         Env.Length := Len;
         declare
            P : Natural := 1;
         begin
            Env.Data (P .. P + Pfx'Length - 1) := Pfx;           P := P + Pfx'Length;
            Env.Data (P .. P + L'Length - 1)   := L;             P := P + L'Length;
            Env.Data (P .. P + Sep'Length - 1) := Sep;           P := P + Sep'Length;
            Env.Data (P .. P + Input.Length - 1) :=
              Input.Data (1 .. Input.Length);
         end;
      end if;
      return Env;
   end EMC_Envelope;

   --  Append Suffix to Accumulator (truncate silently if overflow)
   procedure Accumulate
     (Accum  : in out Bounded_Text;
      Suffix : in     Bounded_Text)
   is
      Available : constant Natural := Max_Text_Length - Accum.Length;
      To_Copy   : constant Natural :=
        (if Suffix.Length <= Available then Suffix.Length else Available);
   begin
      Accum.Data (Accum.Length + 1 .. Accum.Length + To_Copy) :=
        Suffix.Data (1 .. To_Copy);
      Accum.Length := Accum.Length + To_Copy;
   end Accumulate;

   --  -----------------------------------------------------------------------

   procedure Run_Inference_Cycle
     (Session_Key : in  Bounded_Text;
      Input       : in  Bounded_Text;
      Output      : out Bounded_Text;
      Status      : out Operation_Status)
   is
      S      : Operation_Status;
      Accum  : Bounded_Text;  --  accumulates enriched context across all steps
      Msg    : Organ_Message;
      Ref    : Soul.State.Session_Ref := Soul.State.No_Session;
   begin
      Output := (others => ' ', Length => 0);
      Inference_Orchestrator.Reset;

      --  Resolve the session for this (uid, channel, server). The cross and
      --  card pool below belong to THIS session only.
      Soul.State.Soul_State.Open_Session (Session_Key, Ref, S);
      if S /= OK then Status := S; return; end if;
      if Ref not in Soul.State.Valid_Session then
         Status := Error_Invalid_State;
         return;
      end if;

      --  Step 1: INPUT. Reset already leaves the orchestrator AT Phase_Input,
      --  so this step does its work directly rather than advancing onto itself.
      Accumulate (Accum, Input);

      --  Step 2: Ada enriches
      Inference_Orchestrator.Advance (Phase_Enrich, S);
      if S /= OK then Status := S; return; end if;
      --  (Drive-Box enrichment deferred to follow-up session;
      --   RAG context would be injected here when implemented.)

      --  Step 3: LLM init
      Inference_Orchestrator.Advance (Phase_LLM_Init, S);
      if S /= OK then Status := S; return; end if;
      --  The Celtic Cross is NOT drawn whole here. It accretes through the
      --  cognitive loops below — 2 cards per layer (steps 6/9/13), the stave
      --  of 4 last (step 17). Once formed it is held for the whole session
      --  (or 17 outputs, whichever is longer); Soul_State owns that state, so
      --  later cycles in the session reuse the same cross instead of redrawing.

      --  Steps 4–5: wMC1 + eMC1
      Inference_Orchestrator.Advance (Phase_WMC1, S);
      if S /= OK then Status := S; return; end if;
      Accumulate (Accum, WMC_Envelope (1, Accum));

      Inference_Orchestrator.Advance (Phase_EMC1, S);
      if S /= OK then Status := S; return; end if;
      Accumulate (Accum, EMC_Envelope (1, Accum));

      --  Step 6: CC layer 1 (Present, Challenge) accretes from the loop
      Inference_Orchestrator.Advance (Phase_CC_1_2, S);
      if S /= OK then Status := S; return; end if;
      if not Soul.State.Soul_State.Is_Spread_Formed (Ref) then
         Soul.State.Soul_State.Form_Layer (Ref, Soul.Celtic_Cross.Layer_1, S);
         if S /= OK then Status := S; return; end if;
      end if;
      Accumulate
        (Accum,
         Soul.Celtic_Cross.Step_6_Context
           (Soul.State.Soul_State.Current_Spread (Ref)));

      --  Steps 7–8: wMC2 + eMC2
      Inference_Orchestrator.Advance (Phase_WMC2, S);
      if S /= OK then Status := S; return; end if;
      Accumulate (Accum, WMC_Envelope (2, Accum));

      Inference_Orchestrator.Advance (Phase_EMC2, S);
      if S /= OK then Status := S; return; end if;
      Accumulate (Accum, EMC_Envelope (2, Accum));

      --  Step 9: CC layer 2 (Foundation, Recent_Past) accretes from the loop
      Inference_Orchestrator.Advance (Phase_CC_3_4, S);
      if S /= OK then Status := S; return; end if;
      if not Soul.State.Soul_State.Is_Spread_Formed (Ref) then
         Soul.State.Soul_State.Form_Layer (Ref, Soul.Celtic_Cross.Layer_2, S);
         if S /= OK then Status := S; return; end if;
      end if;
      Accumulate
        (Accum,
         Soul.Celtic_Cross.Step_9_Context
           (Soul.State.Soul_State.Current_Spread (Ref)));

      --  Step 10: llmCog 1
      Inference_Orchestrator.Advance (Phase_LLM_Cog_1, S);
      if S /= OK then Status := S; return; end if;
      --  (LLM call issued via protocol layer in full implementation)

      --  Steps 11–12: wMC3 + eMC3
      Inference_Orchestrator.Advance (Phase_WMC3, S);
      if S /= OK then Status := S; return; end if;
      Accumulate (Accum, WMC_Envelope (3, Accum));

      Inference_Orchestrator.Advance (Phase_EMC3, S);
      if S /= OK then Status := S; return; end if;
      Accumulate (Accum, EMC_Envelope (3, Accum));

      --  Step 13: CC layer 3 (Crown, Near_Future) accretes from the loop
      Inference_Orchestrator.Advance (Phase_CC_5_6, S);
      if S /= OK then Status := S; return; end if;
      if not Soul.State.Soul_State.Is_Spread_Formed (Ref) then
         Soul.State.Soul_State.Form_Layer (Ref, Soul.Celtic_Cross.Layer_3, S);
         if S /= OK then Status := S; return; end if;
      end if;
      Accumulate
        (Accum,
         Soul.Celtic_Cross.Step_13_Context
           (Soul.State.Soul_State.Current_Spread (Ref)));

      --  Step 14: llmCog 2
      Inference_Orchestrator.Advance (Phase_LLM_Cog_2, S);
      if S /= OK then Status := S; return; end if;

      --  Steps 15–16: wMC4 + eMC4
      Inference_Orchestrator.Advance (Phase_WMC4, S);
      if S /= OK then Status := S; return; end if;
      Accumulate (Accum, WMC_Envelope (4, Accum));

      Inference_Orchestrator.Advance (Phase_EMC4, S);
      if S /= OK then Status := S; return; end if;
      Accumulate (Accum, EMC_Envelope (4, Accum));

      --  Step 17: CC stave (Self_Attitude .. Outcome) pulled as a block once
      --  the 4x4 cognition completes — this is what finishes the cross.
      Inference_Orchestrator.Advance (Phase_CC_7_10, S);
      if S /= OK then Status := S; return; end if;
      if not Soul.State.Soul_State.Is_Spread_Formed (Ref) then
         Soul.State.Soul_State.Form_Layer (Ref, Soul.Celtic_Cross.Stave, S);
         if S /= OK then Status := S; return; end if;
      end if;
      Accumulate
        (Accum,
         Soul.Celtic_Cross.Step_17_Context
           (Soul.State.Soul_State.Current_Spread (Ref)));

      --  Step 18: finalLLMcog
      Inference_Orchestrator.Advance (Phase_Final_Cog, S);
      if S /= OK then Status := S; return; end if;

      --  Step 19: mini-rag (schema lookup — stub until mini-rag organ added)
      Inference_Orchestrator.Advance (Phase_Mini_Rag, S);
      if S /= OK then Status := S; return; end if;

      --  Step 20: sendAda
      Inference_Orchestrator.Advance (Phase_Send_Ada, S);
      if S /= OK then Status := S; return; end if;
      Msg := Make_Internal_Msg (Ada_Medium, Ada_Medium, Accum);

      --  Step 21: Ada routes (trust boundary outbound screen)
      Inference_Orchestrator.Advance (Phase_Route, S);
      if S /= OK then Status := S; return; end if;
      Trust_Boundary.Trust_Guard.Screen_Outbound (Msg, S);
      if S /= OK then Status := S; return; end if;

      --  Step 22: Synthesize
      Inference_Orchestrator.Advance (Phase_Synthesize, S);
      if S /= OK then Status := S; return; end if;

      --  Step 23: Coherence check (intent vs finalLLMcog drift detection)
      Inference_Orchestrator.Advance (Phase_Coherence, S);
      if S /= OK then Status := S; return; end if;

      --  Record the completed output for this session. The session cross is now
      --  held; it will not re-form until Soul_State.Reset_Spread (new session /
      --  floor rollover).
      Soul.State.Soul_State.Note_Output (Ref);

      Output := Accum;
      Status := OK;
   end Run_Inference_Cycle;

   --  -----------------------------------------------------------------------

   function Active_Toolkit return ML_Toolkit is (Toolkit);

   procedure Configure_Tool (Tool : ML_Tool; Enabled : Boolean) is
   begin
      Toolkit (Tool) := (Tool => Tool, Enabled => Enabled);
   end Configure_Tool;

end Ada_Medium;
