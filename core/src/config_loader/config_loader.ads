--  SPARK-safe flat key-value config parser.
--  Reads "key: value" lines; skips blank lines and comments (# prefix).
--  No heap, no exceptions, no finalization — SPARK_Mode On throughout.
with Mafiabot_Types; use Mafiabot_Types;

package Config_Loader
  with SPARK_Mode => On
is

   Max_Keys    : constant := 64;
   Max_Key_Len : constant := 128;
   Max_Val_Len : constant := 512;

   subtype Key_Length is Natural range 0 .. Max_Key_Len;
   subtype Val_Length is Natural range 0 .. Max_Val_Len;

   type Config_Entry is record
      Key     : String (1 .. Max_Key_Len) := (others => ' ');
      Key_Len : Key_Length := 0;
      Val     : String (1 .. Max_Val_Len) := (others => ' ');
      Val_Len : Val_Length := 0;
   end record;

   type Entry_Index is range 1 .. Max_Keys;
   subtype Entry_Count is Natural range 0 .. Max_Keys;

   type Entry_Array is array (Entry_Index) of Config_Entry;

   type Config_Store is record
      Entries : Entry_Array :=
        (others => (Key => (others => ' '), Key_Len => 0,
                    Val => (others => ' '), Val_Len => 0));
      Count : Entry_Count := 0;
   end record;

   --  Parse Buf (a complete file read into a string) into Store.
   procedure Load_From_Buffer
     (Buf    : in     String;
      Store  :    out Config_Store;
      Status :    out Operation_Status)
   with Pre => Buf'Length > 0;

   --  Retrieve the value for Key; returns empty Bounded_Text if not found.
   function Get_Value
     (Store : Config_Store;
      Key   : String) return Bounded_Text;

end Config_Loader;
