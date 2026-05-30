pragma Profile (Jorvik);
pragma SPARK_Mode (On);

package body Engine is

   protected body Core_State is

      procedure Transition_State (New_State : Engine_State) is
      begin
         Current_State := New_State;
      end Transition_State;

      function Get_State return Engine_State is
      begin
         return Current_State;
      end Get_State;

   end Core_State;

   procedure Initialize (Registry : out Daemon_Registry) is
   begin
      Registry := (others => Stopped);
   end Initialize;

   procedure Start_Daemon (Registry : in out Daemon_Registry; D : Daemon_Kind) is
   begin
      Registry (D) := Running;
   end Start_Daemon;

   procedure Stop_Daemon (Registry : in out Daemon_Registry; D : Daemon_Kind) is
   begin
      Registry (D) := Stopped;
   end Stop_Daemon;

   procedure Process_Transaction
     (Sender_Balance : in out Token_Amount;
      Amount         : in     Token_Amount) is
   begin
      Sender_Balance := Sender_Balance - Amount;
   end Process_Transaction;

end Engine;
