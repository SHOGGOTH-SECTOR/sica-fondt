pragma Profile (Jorvik);
pragma SPARK_Mode (On);

--  The Forge. Mathematically proven. Statically verified.
--  If the SPARK prover does not sign off, the binary does not exist.
package Engine is

   --  Exact integer units. No floating-point. No rounding surprises.
   type Token_Amount is range 0 .. 100_000_000_000
     with Size => 64;

   --  The only legal topologies of the engine.
   type Engine_State is
     (Offline, Booting, Synced, Executing_Payload, Fault_Halt);

   --  Ravenscar protected object: the compiler physically rejects race conditions.
   protected Core_State is
      pragma Interrupt_Priority;

      --  Only Booting -> Synced or anything -> Fault_Halt are legal transitions.
      procedure Transition_State (New_State : Engine_State)
        with Pre => (Get_State = Booting and then New_State = Synced)
                    or else New_State = Fault_Halt;

      function Get_State return Engine_State;

   private
      Current_State : Engine_State := Offline;
   end Core_State;

   --  Daemon orchestration layer.
   type Daemon_Kind  is (Economy_Daemon, Network_Daemon, Exploit_Daemon);
   type Daemon_State is (Stopped, Running, Faulted);
   type Daemon_Registry is array (Daemon_Kind) of Daemon_State;

   procedure Initialize (Registry : out Daemon_Registry)
     with Post => (for all D in Daemon_Kind => Registry (D) = Stopped);

   procedure Start_Daemon (Registry : in out Daemon_Registry; D : Daemon_Kind)
     with Pre  => Registry (D) = Stopped,
          Post => Registry (D) = Running
                  and then
                  (for all Other in Daemon_Kind =>
                     (if Other /= D then Registry (Other) = Registry'Old (Other)));

   procedure Stop_Daemon (Registry : in out Daemon_Registry; D : Daemon_Kind)
     with Pre  => Registry (D) = Running,
          Post => Registry (D) = Stopped
                  and then
                  (for all Other in Daemon_Kind =>
                     (if Other /= D then Registry (Other) = Registry'Old (Other)));

   --  The crown jewel: a transaction that cannot underflow.
   --  The SPARK prover will reject any call site that cannot guarantee Sender >= Amount.
   procedure Process_Transaction
     (Sender_Balance : in out Token_Amount;
      Amount         : in     Token_Amount)
     with Pre  => Sender_Balance >= Amount,
          Post => Sender_Balance = Sender_Balance'Old - Amount;

end Engine;
