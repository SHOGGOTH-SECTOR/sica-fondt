with Interfaces.C;
with System;

package Monero_Multisig is
   pragma SPARK_Mode (Off);

   function Prepare_Multisig_Round
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int;

   function Combine_Multisig_Rounds
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int;

end Monero_Multisig;
