package body Trust_Boundary
  with SPARK_Mode => On
is

   function Matches_Blocklist
     (Text : Bounded_Text;
      List : Blocklist) return Boolean
   is
   begin
      for I in Blocklist_Index loop
         declare
            P : constant Pattern_Entry := List (I);
         begin
            if not P.Active or else P.Pattern_Len = 0 then
               goto Next_Pattern;
            end if;
            --  Naive substring search
            if Text.Length >= P.Pattern_Len then
               for J in 1 .. Text.Length - P.Pattern_Len + 1 loop
                  if Text.Data (J .. J + P.Pattern_Len - 1) =
                    P.Pattern (1 .. P.Pattern_Len)
                  then
                     return True;
                  end if;
               end loop;
            end if;
         end;
         <<Next_Pattern>>
         null;
      end loop;
      return False;
   end Matches_Blocklist;

   procedure Validate_Provenance
     (Source  : in  Provenance_Tag;
      Claimed : in  Provenance_Tag;
      Result  : out Operation_Status)
   is
   begin
      if Source /= Claimed then
         Result := Error_Trust_Violation;
      else
         Result := OK;
      end if;
   end Validate_Provenance;

   procedure Check_Rate
     (Limit  : in out Rate_Limit;
      Tick   : in     Natural;
      Result :    out Operation_Status)
   is
   begin
      --  Roll window if we've passed the window boundary
      if Tick - Limit.Window_Start >= Limit.Window_Size then
         Limit.Window_Start  := Tick;
         Limit.Current_Count := 0;
      end if;

      if Limit.Current_Count >= Limit.Max_Per_Window then
         Result := Error_Blocked;
      else
         Limit.Current_Count := Limit.Current_Count + 1;
         Result := OK;
      end if;
   end Check_Rate;

   procedure Check_Message
     (Msg    : in  Organ_Message;
      Result : out Operation_Status)
   is
   begin
      --  System_Internal always passes (SPARK Post condition)
      if Msg.Provenance = System_Internal then
         Result := OK;
         return;
      end if;

      --  Check blocklist
      if Matches_Blocklist (Msg.Payload, Default_Blocklist) then
         Result := Error_Trust_Violation;
         return;
      end if;

      Result := OK;
   end Check_Message;

   protected body Trust_Guard is

      procedure Screen_Inbound
        (Msg    : in  Organ_Message;
         Status : out Operation_Status)
      is
         Rate_Status : Operation_Status;
         Msg_Status  : Operation_Status;
      begin
         Tick := Tick + 1;
         Check_Rate (Inbound_Rate, Tick, Rate_Status);
         if Rate_Status /= OK then
            Status := Rate_Status;
            return;
         end if;
         Check_Message (Msg, Msg_Status);
         Status := Msg_Status;
      end Screen_Inbound;

      procedure Screen_Outbound
        (Msg    : in  Organ_Message;
         Status : out Operation_Status)
      is
         Rate_Status : Operation_Status;
         Msg_Status  : Operation_Status;
      begin
         Tick := Tick + 1;
         Check_Rate (Outbound_Rate, Tick, Rate_Status);
         if Rate_Status /= OK then
            Status := Rate_Status;
            return;
         end if;
         Check_Message (Msg, Msg_Status);
         Status := Msg_Status;
      end Screen_Outbound;

   end Trust_Guard;

end Trust_Boundary;
