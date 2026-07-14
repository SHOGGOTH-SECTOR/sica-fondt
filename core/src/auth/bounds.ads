--  vague roughdraft for authority authentication boundsry.
package bounds is

   --  Exact molecular weight of the vereiner token levels.  No unbounded integers.
   type Token_Value is range 0 .. 512

   --  Strict state topologies.  The system holds exactly one.
   type AuthState is (Offline, Booting, Synced, Executing_Payload, Fault_Halt);

   --  JORVIK protected object.  Concurrent memory safety, no races.
   protected BoundState is
      pragma InterruptPriority;

      --  Guard lives in the body, lock held.  Illegal transition -> Fault_Halt. The 'transaction' is a state check.
      procedure TransitionState (NewState : BoundState);

      function Get_State return BoundState;

   private
      Current_State : AuthState := Offline;
   end Core_State;

   -- not a thing

end Bounds;
