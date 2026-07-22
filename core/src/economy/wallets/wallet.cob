      *> wallet.cob
      *> Monero Wallet Interface in COBOL
      *> Handles wallet balance checks and multisig transaction creation.
      *> Dependencies: Ada bridge functions (ada_get_wallet_balance,
      *>               ada_build_monero_multisig_tx)

       IDENTIFICATION DIVISION.
       PROGRAM-ID. XMR-WALLET.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA.

       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01  WS-STATUS-CODE                  PIC 9(9) COMP-5 VALUE 0.

       01  XMR-SUCCESS                     PIC 9(9) COMP-5 VALUE 0.
       01  XMR-ERROR-INVALID-REQUEST       PIC 9(9) COMP-5 VALUE 1.
       01  XMR-ERROR-BUFFER-TOO-SMALL      PIC 9(9) COMP-5 VALUE 2.
       01  XMR-ERROR-UNSUPPORTED-CHAIN     PIC 9(9) COMP-5 VALUE 3.
       01  XMR-ERROR-CRYPTO-FAILURE        PIC 9(9) COMP-5 VALUE 4.
       01  XMR-ERROR-MULTISIG-INCOMPLETE   PIC 9(9) COMP-5 VALUE 5.
       01  XMR-ERROR-IO-FAILURE            PIC 9(9) COMP-5 VALUE 6.

       01  WS-WALLET-ID                    PIC X(64).
       01  WS-ACCOUNT-ID                   PIC X(64).
       01  WS-DESTINATION-ADDRESS          PIC X(256).
       01  WS-DESTINATION-LEN              PIC 9(4) COMP-5.
       01  WS-AMOUNT-ATOMIC                PIC 9(20) COMP-5.
       01  WS-MULTISIG-REQUIRED            PIC 9(9) COMP-5.
       01  WS-MULTISIG-TOTAL               PIC 9(9) COMP-5.

       01  WS-TX-BLOB.
           05 WS-TX-BUFFER                 PIC X(65536) VALUE SPACES.
           05 WS-TX-BUFFER-MAX             PIC 9(9) COMP-5 VALUE 65536.
           05 WS-TX-BUFFER-LEN             PIC 9(9) COMP-5 VALUE 0.

       01  WS-TX-ID.
           05 WS-TX-ID-BUFFER              PIC X(128) VALUE SPACES.
           05 WS-TX-ID-MAX                 PIC 9(9) COMP-5 VALUE 128.
           05 WS-TX-ID-LEN                 PIC 9(9) COMP-5 VALUE 0.

       01  WS-BALANCE.
           05 WS-BALANCE-ATOMIC            PIC 9(20) COMP-5 VALUE 0.

       01  TEMP-INPUT.
           05 TEMP-AMOUNT                  PIC X(20).
           05 TEMP-REQUIRED               PIC X(5).
           05 TEMP-TOTAL                  PIC X(5).

       PROCEDURE DIVISION.

       MAIN.
           DISPLAY "COBOL MONERO WALLET INTERFACE STARTED".

           DISPLAY "ENTER WALLET ID (max 64 chars): ".
           ACCEPT WS-WALLET-ID.
           DISPLAY "ENTER ACCOUNT ID (max 64 chars): ".
           ACCEPT WS-ACCOUNT-ID.
           DISPLAY "ENTER DESTINATION ADDRESS (max 256 chars): ".
           ACCEPT WS-DESTINATION-ADDRESS.
           MOVE FUNCTION LENGTH(WS-DESTINATION-ADDRESS)
               TO WS-DESTINATION-LEN.
           IF WS-DESTINATION-LEN > 256
               DISPLAY "ERROR: Destination address too long."
               STOP RUN
           END-IF.

           DISPLAY "ENTER AMOUNT (atomic units, max 18 digits): ".
           ACCEPT TEMP-AMOUNT.
           MOVE TEMP-AMOUNT TO WS-AMOUNT-ATOMIC.
           IF WS-AMOUNT-ATOMIC = 0
               DISPLAY "ERROR: Amount must be > 0."
               STOP RUN
           END-IF.

           DISPLAY "ENTER MULTISIG REQUIRED SIGNERS (1-10): ".
           ACCEPT TEMP-REQUIRED.
           MOVE TEMP-REQUIRED TO WS-MULTISIG-REQUIRED.
           DISPLAY "ENTER MULTISIG TOTAL SIGNERS (1-10): ".
           ACCEPT TEMP-TOTAL.
           MOVE TEMP-TOTAL TO WS-MULTISIG-TOTAL.

           IF WS-MULTISIG-REQUIRED <= 0
               OR WS-MULTISIG-TOTAL <= 0
               DISPLAY "ERROR: Signers must be > 0."
               STOP RUN
           END-IF.
           IF WS-MULTISIG-REQUIRED > WS-MULTISIG-TOTAL
               DISPLAY "ERROR: Required > total signers."
               STOP RUN
           END-IF.

           PERFORM CHECK-BALANCE.
           PERFORM CREATE-MONERO-SPEND.

           DISPLAY "COBOL WALLET FINISHED".
           STOP RUN.

       CHECK-BALANCE.
           CALL "ada_get_wallet_balance"
               USING
                   BY REFERENCE WS-WALLET-ID
                   BY REFERENCE WS-ACCOUNT-ID
                   BY REFERENCE WS-BALANCE-ATOMIC
               RETURNING WS-STATUS-CODE
           END-CALL.

           EVALUATE WS-STATUS-CODE
               WHEN XMR-SUCCESS
                   DISPLAY "BALANCE (ATOMIC): " WS-BALANCE-ATOMIC
               WHEN XMR-ERROR-INVALID-REQUEST
                   DISPLAY "BALANCE ERROR: Invalid request."
               WHEN XMR-ERROR-IO-FAILURE
                   DISPLAY "BALANCE ERROR: I/O failure."
               WHEN OTHER
                   DISPLAY "BALANCE ERROR: Code " WS-STATUS-CODE
           END-EVALUATE.

       CREATE-MONERO-SPEND.
           DISPLAY "REQUESTING MONERO MULTISIG SPEND".

           CALL "ada_build_monero_multisig_tx"
               USING
                   BY REFERENCE WS-WALLET-ID
                   BY REFERENCE WS-ACCOUNT-ID
                   BY REFERENCE WS-DESTINATION-ADDRESS
                   BY VALUE     WS-AMOUNT-ATOMIC
                   BY VALUE     WS-MULTISIG-REQUIRED
                   BY VALUE     WS-MULTISIG-TOTAL
                   BY REFERENCE WS-TX-BUFFER
                   BY VALUE     WS-TX-BUFFER-MAX
                   BY REFERENCE WS-TX-BUFFER-LEN
                   BY REFERENCE WS-TX-ID-BUFFER
                   BY VALUE     WS-TX-ID-MAX
                   BY REFERENCE WS-TX-ID-LEN
               RETURNING WS-STATUS-CODE
           END-CALL.

           EVALUATE WS-STATUS-CODE
               WHEN XMR-SUCCESS
                   DISPLAY "TX CREATED SUCCESSFULLY."
                   DISPLAY "TX ID: "
                       WS-TX-ID-BUFFER(1:WS-TX-ID-LEN)
               WHEN XMR-ERROR-INVALID-REQUEST
                   DISPLAY "TX ERROR: Invalid request."
               WHEN XMR-ERROR-BUFFER-TOO-SMALL
                   DISPLAY "TX ERROR: Buffer too small."
               WHEN XMR-ERROR-MULTISIG-INCOMPLETE
                   DISPLAY "TX ERROR: Multisig incomplete."
               WHEN XMR-ERROR-IO-FAILURE
                   DISPLAY "TX ERROR: I/O failure."
               WHEN OTHER
                   DISPLAY "TX ERROR: Code " WS-STATUS-CODE
           END-EVALUATE.
