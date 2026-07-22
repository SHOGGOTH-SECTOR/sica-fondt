with Interfaces.C;
with System;

package Fortran_Crypto is
   pragma SPARK_Mode (Off);

   function XMR_Hash_To_Scalar
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_hash_to_scalar";

   function XMR_Hash_To_Point
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_hash_to_point";

   function XMR_Generate_Key_Image
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_generate_key_image";

   function XMR_Generate_RingCT
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_generate_ringct";

   function XMR_Verify_RingCT
     (Input_Buffer : System.Address;
      Input_Length : Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_verify_ringct";

   function XMR_Multisig_Prepare
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_multisig_prepare";

   function XMR_Multisig_Combine
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_multisig_combine";

   function XMR_Generate_CLSAG
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_generate_clsag";

   function XMR_Generate_Bulletproof
     (Input_Buffer  : System.Address;
      Input_Length  : Interfaces.C.int;
      Output_Buffer : System.Address;
      Output_Max    : Interfaces.C.int;
      Output_Length : access Interfaces.C.int)
      return Interfaces.C.int
   with Import, Convention => C, External_Name => "xmr_generate_bulletproof";

end Fortran_Crypto;
