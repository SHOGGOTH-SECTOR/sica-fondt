with Interfaces.C;
with System;

package Ada_Bridge is
   pragma SPARK_Mode (Off);

   function Ada_Get_Wallet_Balance
     (Wallet_Id  : System.Address;
      Account_Id : System.Address;
      Balance    : access Interfaces.C.unsigned_long_long)
      return Interfaces.C.int
   with Export, Convention => C, External_Name => "ada_get_wallet_balance";

   function Ada_Build_Monero_Multisig_Tx
     (Wallet_Id            : System.Address;
      Account_Id           : System.Address;
      Destination_Address  : System.Address;
      Amount_Atomic        : Interfaces.C.unsigned_long_long;
      Required_Signers     : Interfaces.C.int;
      Total_Signers        : Interfaces.C.int;
      Tx_Buffer            : System.Address;
      Tx_Buffer_Max        : Interfaces.C.int;
      Tx_Buffer_Length     : access Interfaces.C.int;
      Tx_Id_Buffer         : System.Address;
      Tx_Id_Max            : Interfaces.C.int;
      Tx_Id_Length         : access Interfaces.C.int)
      return Interfaces.C.int
   with Export, Convention => C, External_Name => "ada_build_monero_multisig_tx";

end Ada_Bridge;
