with Interfaces.C;

package Monero_Types is
   pragma SPARK_Mode (On);

   subtype Status_Code is Interfaces.C.int;

   Success                  : constant Status_Code := 0;
   Error_Invalid_Request    : constant Status_Code := 1;
   Error_Buffer_Too_Small   : constant Status_Code := 2;
   Error_Unsupported_Chain  : constant Status_Code := 3;
   Error_Crypto_Failure     : constant Status_Code := 4;
   Error_Multisig_Incomplete : constant Status_Code := 5;
   Error_IO_Failure         : constant Status_Code := 6;

   type Atomic_Amount is mod 2 ** 64;

   type Monero_Tx_State is
     (Draft,
      Inputs_Selected,
      Rings_Selected,
      RingCT_Prepared,
      Multisig_Partial,
      Multisig_Complete,
      Finalized,
      Submitted,
      Failed);

   type Signature_Status is (Missing, Present, Invalid, Accepted);

   type Participant_Id is range 1 .. 10;

   type Multisig_Participant is record
      Id     : Participant_Id;
      Status : Signature_Status;
   end record;

   type Multisig_Participant_Array is
     array (1 .. 10) of Multisig_Participant;

   type Tx_Context is record
      Amount_Atomic    : Atomic_Amount;
      Required_Signers : Positive range 1 .. 10;
      Total_Signers    : Positive range 1 .. 10;
      State            : Monero_Tx_State;
   end record;

   function Threshold_Reached
     (Participants : Multisig_Participant_Array;
      Required     : Positive)
      return Boolean
   with Pre => Required <= 10;

end Monero_Types;
