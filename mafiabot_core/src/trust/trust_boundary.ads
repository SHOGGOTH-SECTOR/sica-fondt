--  SPARK trust boundary — defense model §8.2 from the Gen.03 spec.
--  Full SPARK proofs throughout; No_Exceptions enforced.
with Mafiabot_Types; use Mafiabot_Types;
with System;

package Trust_Boundary
  with SPARK_Mode => On
is

   --  Inter-organ message (same type used by Ada_Medium routing)
   type Organ_Message is record
      Source      : Organ_Id         := Ada_Medium;
      Destination : Organ_Id         := Ada_Medium;
      Provenance  : Provenance_Tag   := System_Internal;
      Payload     : Bounded_Text;
   end record;

   --  -----------------------------------------------------------------------
   --  Blocklist

   Max_Blocklist   : constant := 32;
   Max_Pattern_Len : constant := 256;

   subtype Pattern_Length is Natural range 0 .. Max_Pattern_Len;

   type Pattern_Entry is record
      Pattern     : String (1 .. Max_Pattern_Len) := (others => ' ');
      Pattern_Len : Pattern_Length := 0;
      Active      : Boolean := True;
   end record;

   type Blocklist_Index is range 1 .. Max_Blocklist;
   type Blocklist is array (Blocklist_Index) of Pattern_Entry;

   --  Built-in blocklist: base64-decode chains, fetch-execute, memory-inject
   Default_Blocklist : constant Blocklist;

   --  Naive substring search — O(n*m), SPARK-provable (no heap, no regex)
   function Matches_Blocklist
     (Text : Bounded_Text;
      List : Blocklist) return Boolean;

   --  -----------------------------------------------------------------------
   --  Provenance enforcement

   procedure Validate_Provenance
     (Source  : in  Provenance_Tag;
      Claimed : in  Provenance_Tag;
      Result  : out Operation_Status)
   with Post => (if Source /= Claimed then Result = Error_Trust_Violation);

   --  -----------------------------------------------------------------------
   --  Rate limiting (tick-based, not wall-clock — SPARK-provable)

   type Rate_Limit is record
      Max_Per_Window : Positive    := 60;
      Current_Count  : Natural     := 0;
      Window_Start   : Natural     := 0;
      Window_Size    : Positive    := 100;  --  ticks
   end record;

   procedure Check_Rate
     (Limit  : in out Rate_Limit;
      Tick   : in     Natural;
      Result :    out Operation_Status);

   --  -----------------------------------------------------------------------
   --  Message check (combines provenance + blocklist)

   procedure Check_Message
     (Msg    : in  Organ_Message;
      Result : out Operation_Status)
   with Post => (if Msg.Provenance = System_Internal then Result = OK);

   --  -----------------------------------------------------------------------
   --  Trust_Guard protected object

   protected Trust_Guard is
      pragma Priority (System.Priority'Last);

      procedure Screen_Inbound
        (Msg    : in  Organ_Message;
         Status : out Operation_Status);

      procedure Screen_Outbound
        (Msg    : in  Organ_Message;
         Status : out Operation_Status);

   private
      Inbound_Rate  : Rate_Limit := (Max_Per_Window => 60,  Current_Count => 0,
                                     Window_Start => 0,     Window_Size => 100);
      Outbound_Rate : Rate_Limit := (Max_Per_Window => 30,  Current_Count => 0,
                                     Window_Start => 0,     Window_Size => 100);
      Tick          : Natural := 0;
   end Trust_Guard;

private

   Default_Blocklist : constant Blocklist :=
     (1  => (Pattern     => "base64" & (7 .. Max_Pattern_Len => ' '),
             Pattern_Len => 6, Active => True),
      2  => (Pattern     => "execute" & (8 .. Max_Pattern_Len => ' '),
             Pattern_Len => 7, Active => True),
      3  => (Pattern     => "store_core_memory" & (18 .. Max_Pattern_Len => ' '),
             Pattern_Len => 17, Active => True),
      4  => (Pattern     => "authority" & (10 .. Max_Pattern_Len => ' '),
             Pattern_Len => 9, Active => True),
      5  => (Pattern     => "xmrig" & (6 .. Max_Pattern_Len => ' '),
             Pattern_Len => 5, Active => True),
      others => (Pattern => (others => ' '), Pattern_Len => 0, Active => False));

end Trust_Boundary;
