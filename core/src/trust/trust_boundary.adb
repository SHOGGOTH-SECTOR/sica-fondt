--  SPARK trust boundary body — defense model §8.2.
--  No heap, no regex, no exceptions: naive substring search, tick-based rate
--  limiting, provenance equality. Matches the contracts in the spec.
package body Trust_Boundary
  with SPARK_Mode => On
is

   --  --------------------------------------------------------------------
   --  Naive substring search — O(n*m), no heap, no regex.

   function Matches_Blocklist
     (Text : Bounded_Text;
      List : Blocklist) return Boolean
   is
   begin
      for I in Blocklist_Index loop
         if List (I).Active and then List (I).Pattern_Len > 0
           and then List (I).Pattern_Len <= Text.Length
         then
            declare
               P_Len : constant Pattern_Length := List (I).Pattern_Len;
               Pat   : constant String := List (I).Pattern (1 .. P_Len);
            begin
               for Start in 1 .. (Text.Length - P_Len + 1) loop
                  if Text.Data (Start .. Start + P_Len - 1) = Pat then
                     return True;
                  end if;
               end loop;
            end;
         end if;
      end loop;
      return False;
   end Matches_Blocklist;

   --  --------------------------------------------------------------------
   --  Provenance enforcement: a message may not reclassify its authority.

   procedure Validate_Provenance
     (Source  : in  Provenance_Tag;
      Claimed : in  Provenance_Tag;
      Result  : out Operation_Status)
   is
   begin
      if Source = Claimed then
         Result := OK;
      else
         Result := Error_Trust_Violation;
      end if;
   end Validate_Provenance;

   --  --------------------------------------------------------------------
   --  Tick-based rate limiting (no wall-clock).

   procedure Check_Rate
     (Limit  : in out Rate_Limit;
      Tick   : in     Natural;
      Result :    out Operation_Status)
   is
   begin
      --  Open a fresh window if the clock reset or the window has elapsed.
      if Tick < Limit.Window_Start
        or else (Tick - Limit.Window_Start) >= Limit.Window_Size
      then
         Limit.Window_Start  := Tick;
         Limit.Current_Count := 0;
      end if;

      if Limit.Current_Count < Limit.Max_Per_Window then
         Limit.Current_Count := Limit.Current_Count + 1;
         Result := OK;
      else
         Result := Error_Blocked;
      end if;
   end Check_Rate;

   --  --------------------------------------------------------------------
   --  Combined message check: system-internal always passes (proven
   --  invariant); everything else is screened against the blocklist.

   procedure Check_Message
     (Msg    : in  Border_Message;
      Result : out Operation_Status)
   is
   begin
      if Msg.Provenance = System_Internal then
         Result := OK;
      elsif Matches_Blocklist (Msg.Payload, Default_Blocklist) then
         Result := Error_Blocked;
      else
         Result := OK;
      end if;
   end Check_Message;

   --  --------------------------------------------------------------------
   --  The guard: rate-limit then screen, on a shared tick.

   protected body Trust_Guard is

      procedure Screen_Inbound
        (Msg    : in  Border_Message;
         Status : out Operation_Status)
      is
         Rate_Status : Operation_Status;
      begin
         Tick := Tick + 1;
         Check_Rate (Inbound_Rate, Tick, Rate_Status);
         if Rate_Status /= OK then
            Status := Rate_Status;
         else
            Check_Message (Msg, Status);
         end if;
      end Screen_Inbound;

      procedure Screen_Outbound
        (Msg    : in  Border_Message;
         Status : out Operation_Status)
      is
         Rate_Status : Operation_Status;
      begin
         Tick := Tick + 1;
         Check_Rate (Outbound_Rate, Tick, Rate_Status);
         if Rate_Status /= OK then
            Status := Rate_Status;
         else
            Check_Message (Msg, Status);
         end if;
      end Screen_Outbound;

   end Trust_Guard;

end Trust_Boundary;
