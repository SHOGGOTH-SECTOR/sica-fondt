--  Soul_State protected object.
--
--  Holds two kinds of state:
--    * Global identity — the Big-3 (Sun/Moon/Ascendant). This is WHO Ada is,
--      immutable once set, shared across every conversation.
--    * Per-session context — each (uid, channel, server) tuple gets its own
--      dynamic card pool, Celtic Cross spread, and output counter. The cross
--      forms from that session's cognitive loops and is held for the session
--      (or Spread_Output_Floor outputs, whichever is longer). Two users on two
--      channels never share a deck or a cross.
--
--  Generates SOUL.md content for the Hermes Agent identity slot.
with Soul.Tarot;
with Soul.Celtic_Cross;
with Mafiabot_Types; use Mafiabot_Types;
with System;

package Soul.State
  with SPARK_Mode => On
is

   --  Lifetime floor for a Celtic Cross spread. A formed cross is held for
   --  the whole session OR this many outputs, whichever is longer. Within a
   --  single running binary the session always wins (the cross is formed once
   --  and held); the floor only governs carrying a spread across a restart,
   --  which requires deck-state serialisation (deferred).
   Spread_Output_Floor : constant := 17;

   --  Maximum number of concurrent sessions (uid x channel x server tuples).
   Max_Sessions : constant := 64;

   --  Opaque session handle. 0 is the null handle (no session); 1 .. Max is a
   --  live slot returned by Open_Session.
   type Session_Ref is range 0 .. Max_Sessions;
   No_Session : constant Session_Ref := 0;
   subtype Valid_Session is Session_Ref range 1 .. Max_Sessions;

   --  Compose a canonical session key from the routing identity. Any field may
   --  be empty; missing fields default to "default" so a bare call still maps
   --  to a stable session.
   function Make_Session_Key
     (Uid     : String;
      Channel : String;
      Server  : String) return Bounded_Text;

   protected Soul_State is
      pragma Priority (System.Priority'Last - 2);

      --  Set the three immutable personality anchors. Fails if called twice.
      procedure Initialize_Big_Three
        (B3     : in  Soul.Tarot.Big_Three;
         Status : out Operation_Status)
      with Post => (if Status = OK then Is_Initialized);

      --  Resolve a session by key, allocating a fresh slot (with its own
      --  Big-3-pruned deck) on first sight. Returns No_Session +
      --  Error_Overflow if the table is full.
      procedure Open_Session
        (Key    : in  Bounded_Text;
         Ref    : out Session_Ref;
         Status : out Operation_Status)
      with Pre  => Is_Initialized,
           Post => (if Status = OK then Ref in Valid_Session);

      --  Accrete one cognitive layer of THIS session's cross from its pool.
      --  Idempotent per layer: re-forming an already-formed layer is a no-op
      --  returning OK. The cross builds across the 4x4 multicycle (Layer_1/2/3
      --  = 2 cards each, Stave = 4), then is held for the session.
      procedure Form_Layer
        (Ref    : in  Valid_Session;
         Layer  : in  Soul.Celtic_Cross.CC_Layer;
         Status : out Operation_Status);

      --  Clear THIS session's cross so a fresh one forms (new session / floor
      --  rollover). Does not touch Big-3 or refill the deck.
      procedure Reset_Spread (Ref : in Valid_Session);

      --  Record that one output (inference cycle) completed for THIS session.
      procedure Note_Output (Ref : in Valid_Session);

      --  Serialise the global identity into Bounded_Text for SOUL.md.
      procedure Generate_Soul_MD
        (Buffer : out Bounded_Text;
         Status : out Operation_Status)
      with Pre => Is_Initialized;

      function Is_Initialized return Boolean;
      function Get_Big_Three  return Soul.Tarot.Big_Three;

      function Is_Spread_Formed (Ref : Valid_Session) return Boolean;
      function Current_Spread   (Ref : Valid_Session)
        return Soul.Celtic_Cross.CC_Spread;
      function Output_Count     (Ref : Valid_Session) return Natural;
      function Session_Count    return Natural;

   private
      Big_3       : Soul.Tarot.Big_Three;
      Initialized : Boolean := False;

      Max_Key : constant := 192;
      subtype Key_Length is Natural range 0 .. Max_Key;
      type Session_Key is record
         Data   : String (1 .. Max_Key) := (others => ' ');
         Length : Key_Length := 0;
      end record;

      type Layer_Flags is
        array (Soul.Celtic_Cross.CC_Layer) of Boolean;

      type Session_Slot is record
         In_Use         : Boolean := False;
         Key            : Session_Key;
         Deck           : Soul.Tarot.Deck := Soul.Tarot.Full_Deck;
         Spread         : Soul.Celtic_Cross.CC_Spread :=
           Soul.Celtic_Cross.Empty_Spread;
         Layer_Done     : Layer_Flags := (others => False);
         Output_Counter : Natural := 0;
      end record;

      type Session_Table is array (Valid_Session) of Session_Slot;

      Sessions : Session_Table;
   end Soul_State;

end Soul.State;
