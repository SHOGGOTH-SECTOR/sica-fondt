with Fortran_Crypto;

package body Monero_Multisig is
   pragma SPARK_Mode (Off);

   function Prepare_Multisig_Round
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   is
   begin
      return Fortran_Crypto.XMR_Multisig_Prepare
        (Input_Buffer, Input_Length,
         Output_Buffer, Output_Max, Output_Length);
   end Prepare_Multisig_Round;

   function Combine_Multisig_Rounds
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   is
   begin
      return Fortran_Crypto.XMR_Multisig_Combine
        (Input_Buffer, Input_Length,
         Output_Buffer, Output_Max, Output_Length);
   end Combine_Multisig_Rounds;

end Monero_Multisig;
