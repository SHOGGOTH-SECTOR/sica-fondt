--  I/O-facing package: SPARK_Mode Off.
--  Environment reads are external state; prove the callers, not the reader.
pragma SPARK_Mode (Off);

package Bot_Config is

   Config_Missing : exception;

   Max_Token_Length : constant := 256;
   Max_Guild_Length : constant := 64;

   subtype Token_Buffer is String (1 .. Max_Token_Length);
   subtype Guild_Buffer is String (1 .. Max_Guild_Length);

   type Bot_Configuration is record
      Bot_Token       : Token_Buffer := (others => ' ');
      Token_Length    : Natural      := 0;
      Guild_ID        : Guild_Buffer := (others => ' ');
      Guild_Length    : Natural      := 0;
      Command_Prefix  : Character   := '!';
      Max_Connections : Positive    := 4;
      Request_Timeout : Duration    := 30.0;
   end record;

   function  Load     return Bot_Configuration;
   procedure Validate (Config : Bot_Configuration);

end Bot_Config;
