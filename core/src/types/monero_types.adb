package body Monero_Types is
   pragma SPARK_Mode (On);

   function Threshold_Reached
     (Participants : Multisig_Participant_Array;
      Required     : Positive)
      return Boolean
   is
      Count : Natural := 0;
   begin
      for P of Participants loop
         if P.Status = Accepted then
            Count := Count + 1;
         end if;
         if Count >= Required then
            return True;
         end if;
      end loop;
      return False;
   end Threshold_Reached;

end Monero_Types;
