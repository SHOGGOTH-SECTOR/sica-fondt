with Interfaces.C;

package body Monero_IO is
   pragma SPARK_Mode (Off);

   function Fetch_Spendable_Outputs
     (Wallet_Buffer : System.Address;
      Wallet_Length : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   is
      pragma Unreferenced (Wallet_Buffer, Wallet_Length);
      pragma Unreferenced (Output_Buffer, Output_Max);
   begin
      Output_Length.all := 0;
      return 0;
   end Fetch_Spendable_Outputs;

   function Fetch_Ring_Members
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   is
      pragma Unreferenced (Input_Buffer, Input_Length);
      pragma Unreferenced (Output_Buffer, Output_Max);
   begin
      Output_Length.all := 0;
      return 0;
   end Fetch_Ring_Members;

   function Broadcast_Transaction
     (Tx_Buffer : System.Address;
      Tx_Length : Interfaces.C.int)
      return Interfaces.C.int
   is
      pragma Unreferenced (Tx_Buffer, Tx_Length);
   begin
      return 0;
   end Broadcast_Transaction;

end Monero_IO;
