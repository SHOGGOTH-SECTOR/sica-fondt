with Interfaces.C;
with System;
with Monero_IO;
with Monero_Multisig;
with Fortran_Crypto;
with Monero_Types;

package body Ada_Bridge is
   pragma SPARK_Mode (Off);

   Scratch_Max : constant Interfaces.C.int := 65536;

   type Byte is mod 2 ** 8;
   type Byte_Array is array (Natural range <>) of aliased Byte;

   function Ada_Get_Wallet_Balance
     (Wallet_Id  : System.Address;
      Account_Id : System.Address;
      Balance    : access Interfaces.C.unsigned_long_long)
      return Interfaces.C.int
   is
      pragma Unreferenced (Wallet_Id, Account_Id);
   begin
      Balance.all := 0;
      return Monero_Types.Success;
   exception
      when others =>
         return Monero_Types.Error_IO_Failure;
   end Ada_Get_Wallet_Balance;

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
   is
      pragma Unreferenced (Account_Id);
      Status : Interfaces.C.int;

      Spendable_Outputs : Byte_Array (0 .. Natural (Scratch_Max) - 1);
      Spendable_Length  : aliased Interfaces.C.int := 0;

      Ring_Members      : Byte_Array (0 .. Natural (Scratch_Max) - 1);
      Ring_Length        : aliased Interfaces.C.int := 0;

      Multisig_Round    : Byte_Array (0 .. Natural (Scratch_Max) - 1);
      Multisig_Length   : aliased Interfaces.C.int := 0;

      RingCT_Output     : Byte_Array (0 .. Natural (Scratch_Max) - 1);
      RingCT_Length     : aliased Interfaces.C.int := 0;

      CLSAG_Output      : Byte_Array (0 .. Natural (Scratch_Max) - 1);
      CLSAG_Length      : aliased Interfaces.C.int := 0;

      Bulletproof_Out   : Byte_Array (0 .. Natural (Scratch_Max) - 1);
      Bulletproof_Len   : aliased Interfaces.C.int := 0;
   begin
      if Destination_Address = System.Null_Address
        or else Amount_Atomic = 0
      then
         return Monero_Types.Error_Invalid_Request;
      end if;

      if Required_Signers <= 0
        or else Total_Signers <= 0
        or else Required_Signers > Total_Signers
      then
         return Monero_Types.Error_Invalid_Request;
      end if;

      if Tx_Buffer_Max <= 0 or else Tx_Id_Max < 64 then
         return Monero_Types.Error_Buffer_Too_Small;
      end if;

      Status :=
        Monero_IO.Fetch_Spendable_Outputs
          (Wallet_Buffer => Wallet_Id,
           Wallet_Length => 64,
           Output_Buffer => Spendable_Outputs (0)'Address,
           Output_Max    => Scratch_Max,
           Output_Length => Spendable_Length'Access);
      if Status /= Monero_Types.Success then
         return Status;
      end if;

      Status :=
        Monero_IO.Fetch_Ring_Members
          (Input_Buffer  => Spendable_Outputs (0)'Address,
           Input_Length  => Spendable_Length,
           Output_Buffer => Ring_Members (0)'Address,
           Output_Max    => Scratch_Max,
           Output_Length => Ring_Length'Access);
      if Status /= Monero_Types.Success then
         return Status;
      end if;

      Status :=
        Monero_Multisig.Prepare_Multisig_Round
          (Input_Buffer  => Ring_Members (0)'Address,
           Input_Length  => Ring_Length,
           Output_Buffer => Multisig_Round (0)'Address,
           Output_Max    => Scratch_Max,
           Output_Length => Multisig_Length'Access);
      if Status /= Monero_Types.Success then
         return Status;
      end if;

      Status :=
        Fortran_Crypto.XMR_Generate_RingCT
          (Input_Buffer  => Multisig_Round (0)'Address,
           Input_Length  => Multisig_Length,
           Output_Buffer => RingCT_Output (0)'Address,
           Output_Max    => Scratch_Max,
           Output_Length => RingCT_Length'Access);
      if Status /= Monero_Types.Success then
         return Status;
      end if;

      Status :=
        Fortran_Crypto.XMR_Generate_CLSAG
          (Input_Buffer  => RingCT_Output (0)'Address,
           Input_Length  => RingCT_Length,
           Output_Buffer => CLSAG_Output (0)'Address,
           Output_Max    => Scratch_Max,
           Output_Length => CLSAG_Length'Access);
      if Status /= Monero_Types.Success then
         return Status;
      end if;

      Status :=
        Fortran_Crypto.XMR_Generate_Bulletproof
          (Input_Buffer  => CLSAG_Output (0)'Address,
           Input_Length  => CLSAG_Length,
           Output_Buffer => Bulletproof_Out (0)'Address,
           Output_Max    => Scratch_Max,
           Output_Length => Bulletproof_Len'Access);
      if Status /= Monero_Types.Success then
         return Status;
      end if;

      if Bulletproof_Len > Tx_Buffer_Max then
         return Monero_Types.Error_Buffer_Too_Small;
      end if;

      Tx_Buffer_Length.all := Bulletproof_Len;
      declare
         Tx_Out : Byte_Array (0 .. Natural (Tx_Buffer_Max) - 1)
           with Address => Tx_Buffer;
      begin
         Tx_Out (0 .. Natural (Bulletproof_Len) - 1) :=
           Bulletproof_Out (0 .. Natural (Bulletproof_Len) - 1);
      end;

      Tx_Id_Length.all := 64;
      declare
         Tx_Id_Out : Byte_Array (0 .. Natural (Tx_Id_Max) - 1)
           with Address => Tx_Id_Buffer;
      begin
         Tx_Id_Out (0 .. 63) := Bulletproof_Out (0 .. 63);
      end;

      Status :=
        Monero_IO.Broadcast_Transaction
          (Tx_Buffer, Tx_Buffer_Length.all);
      if Status /= Monero_Types.Success then
         return Status;
      end if;

      return Monero_Types.Success;

   exception
      when others =>
         return Monero_Types.Error_IO_Failure;
   end Ada_Build_Monero_Multisig_Tx;

end Ada_Bridge;
