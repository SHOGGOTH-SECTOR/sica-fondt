pragma Profile (Jorvik);
pragma SPARK_Mode (On);

--  The casino math daemon. Fixed-point decimal. No Float. Ever.
package Economy is

   --  One hundred billion units max. delta 0.01 for cent-precision.
   type Token_Amount is delta 0.01 range 0.00 .. 1_000_000_000.00
     with Small => 0.01;

   type Player_ID is new Positive range 1 .. 10_000;

   type Balance_Entry is record
      ID      : Player_ID;
      Balance : Token_Amount := 0.00;
      Wagered : Token_Amount := 0.00;
   end record;

   Max_Entries : constant := 10_000;
   type Ledger_Index is range 1 .. Max_Entries;
   type Ledger_Array is array (Ledger_Index) of Balance_Entry;

   type Ledger is record
      Entries : Ledger_Array;
      Count   : Natural := 0;
   end record
     with Predicate => Ledger.Count <= Max_Entries;

   Insufficient_Funds : exception;
   Player_Not_Found   : exception;

   procedure Register (L : in out Ledger; ID : Player_ID)
     with Pre  => L.Count < Max_Entries,
          Post => L.Count = L.Count'Old + 1;

   function Balance_Of (L : Ledger; ID : Player_ID) return Token_Amount
     with Pre => (for some I in Ledger_Index range 1 .. Ledger_Index (L.Count) =>
                    L.Entries (I).ID = ID);

   procedure Deposit
     (L      : in out Ledger;
      ID     : Player_ID;
      Amount : Token_Amount)
     with Pre => (for some I in Ledger_Index range 1 .. Ledger_Index (L.Count) =>
                    L.Entries (I).ID = ID);

   procedure Place_Wager
     (L      : in out Ledger;
      ID     : Player_ID;
      Amount : Token_Amount)
     with Pre => (for some I in Ledger_Index range 1 .. Ledger_Index (L.Count) =>
                    L.Entries (I).ID = ID
                    and then L.Entries (I).Balance >= Amount);

   procedure Resolve_Wager
     (L   : in out Ledger;
      ID  : Player_ID;
      Won : Boolean)
     with Pre => (for some I in Ledger_Index range 1 .. Ledger_Index (L.Count) =>
                    L.Entries (I).ID = ID);

end Economy;
