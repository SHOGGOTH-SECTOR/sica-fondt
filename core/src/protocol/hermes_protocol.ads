--  Hermes MCP stdio bridge.
--  SPARK_Mode Off sections are justified: trust boundary checks happen
--  in SPARK-proven code (Ada_Medium / Trust_Boundary) before any I/O call.
--  This package handles only the process boundary crossing.
with Mafiabot_Types; use Mafiabot_Types;

package Hermes_Protocol
  with SPARK_Mode => Off  --  Ada.Text_IO is not SPARK-compatible
is

   Max_JSON_Length : constant := 8192;

   --  Raw JSON buffer (stack-allocated, 8 KiB)
   subtype JSON_Length is Natural range 0 .. Max_JSON_Length;
   type JSON_Buffer is record
      Data   : String (1 .. Max_JSON_Length) := (others => ' ');
      Length : JSON_Length := 0;
   end record;

   --  Read one JSON-RPC message from stdin (newline-delimited).
   --  Returns Error_Overflow if the line exceeds Max_JSON_Length.
   procedure Read_Message
     (Buf    : out JSON_Buffer;
      Status : out Operation_Status);

   --  Write one JSON-RPC response to stdout followed by a newline.
   procedure Write_Message (Buf : in JSON_Buffer);

   --  Extract the string value for a top-level JSON key.
   --  Simple state machine: finds `"key": "value"` patterns only.
   --  Returns empty Bounded_Text if the key is absent.
   procedure Extract_Field
     (Buf   : in  JSON_Buffer;
      Key   : in  String;
      Value : out Bounded_Text);

   --  Extract the RAW value token for a key, verbatim, preserving its JSON
   --  type: a quoted string keeps its quotes, a number/literal is copied as
   --  digits. Used for `id`, which must be echoed back unchanged. Returns the
   --  literal `null` if the key is absent.
   procedure Extract_Raw_Field
     (Buf   : in  JSON_Buffer;
      Key   : in  String;
      Value : out Bounded_Text);

   --  Write the SOUL.md content to ~/.hermes/SOUL.md.
   procedure Write_Soul_MD
     (Content : in  Bounded_Text;
      Status  : out Operation_Status);

   --  Build the standard MCP initialize response.
   procedure Make_Init_Response
     (Id  : in  Bounded_Text;
      Buf : out JSON_Buffer);

   --  Build the tools/list response exposing the inference cycle tool.
   procedure Make_Tools_List_Response
     (Id  : in  Bounded_Text;
      Buf : out JSON_Buffer);

   --  Build a tools/call result response wrapping the inference output.
   procedure Make_Tool_Result_Response
     (Id     : in  Bounded_Text;
      Result : in  Bounded_Text;
      Buf    : out JSON_Buffer);

   --  Build a JSON-RPC error response.
   procedure Make_Error_Response
     (Id      : in  Bounded_Text;
      Code    : in  Integer;
      Message : in  String;
      Buf     : out JSON_Buffer);

end Hermes_Protocol;
