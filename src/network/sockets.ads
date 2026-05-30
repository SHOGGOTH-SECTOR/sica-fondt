--  External I/O: SPARK_Mode Off.
--  GNAT.Sockets uses access types; prove the callers via contracts on this boundary.
pragma SPARK_Mode (Off);

with GNAT.Sockets; use GNAT.Sockets;

package Sockets is

   type Connection is record
      Sock   : Socket_Type := No_Socket;
      Port   : Port_Type   := 443;
      Active : Boolean     := False;
   end record;

   Connect_Failed  : exception;
   Send_Failed     : exception;
   Receive_Failed  : exception;

   procedure Open_Connection
     (C    : out Connection;
      Host : String;
      Port : Port_Type := 443);

   procedure Close_Connection (C : in out Connection);

   procedure Send_Raw    (C : Connection; Data : String);
   function  Receive_Raw (C : Connection) return String;
   function  Is_Active   (C : Connection) return Boolean;

end Sockets;
