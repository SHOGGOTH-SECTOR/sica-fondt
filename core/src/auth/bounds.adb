--  The implementation of the Forge.
package body bounds is

   protected body Core_State is

      --  Checked with the lock held.  Only Booting -> Synced is legal;
      --  Fault_Halt is always reachable; anything else forces Fault_Halt.
      procedure Transition_State (New_State : Engine_State) is
      begin
         if (Current_State = Booting and then New_State = Synced)
           or else New_State = Fault_Halt
         then
            Current_State := New_State;
         else
            Current_State := Fault_Halt;
         end if;
      end Transition_State;

      function Get_State return Engine_State is
      begin
         return Current_State;
      end Get_State;

   end Core_State;

   --  The Pre guarantees Sender_Balance >= Amount, so this subtraction can
   --  never underflow.  SPARK proves it statically; no runtime handler needed.
   procedure Process_Transaction (Sender_Balance : in out Token_Amount;
                                  Amount         : in     Token_Amount) is
   begin
      Sender_Balance := Sender_Balance - Amount;
   end Process_Transaction;

end Engine;
