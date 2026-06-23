--  The absolute, irrefutable blueprint of the Engine.
package Engine is

   --  Exact molecular weight of the economy.  No unbounded integers.
   type Token_Amount is range 0 .. 100_000_000_000;

   --  Strict state topologies.  The system holds exactly one.
   type Engine_State is (Offline, Booting, Synced, Executing_Payload, Fault_Halt);

   --  Ravenscar protected object.  Concurrent memory safety, no races.
   protected Core_State is
      pragma Interrupt_Priority;

      --  Guard lives in the body, lock held.  Illegal transition -> Fault_Halt.
      procedure Transition_State (New_State : Engine_State);

      function Get_State return Engine_State;

   private
      Current_State : Engine_State := Offline;
   end Core_State;

   --  Financial transaction with SPARK proofs attached.
   procedure Process_Transaction (Sender_Balance : in out Token_Amount;
                                  Amount         : in     Token_Amount)
      with Pre  => Sender_Balance >= Amount,
           Post => Sender_Balance = Sender_Balance'Old - Amount;

end Engine;
