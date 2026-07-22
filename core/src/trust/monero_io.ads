with Interfaces.C;
with System;

package Monero_IO is
   pragma SPARK_Mode (Off);

   function Fetch_Spendable_Outputs
     (Wallet_Buffer : System.Address;
      Wallet_Length : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int;

   function Fetch_Ring_Members
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int;

   function Broadcast_Transaction
     (Tx_Buffer : System.Address;
      Tx_Length : Interfaces.C.int)
      return Interfaces.C.int;

end Monero_IO;
