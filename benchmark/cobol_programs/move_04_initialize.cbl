       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE-INITIALIZE.
      *---------------------------------------------------------------
      * MOVE ZEROS/SPACES patterns - record reset and defaults
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TRANSACTION-REC.
           05  WS-TXN-ID       PIC X(12)    VALUE 'TXN-00001234'.
           05  WS-TXN-TYPE     PIC X(4)     VALUE 'DEBI'.
           05  WS-TXN-AMOUNT   PIC 9(8)V99  VALUE 1500.75.
           05  WS-TXN-DATE     PIC 9(8)     VALUE 20240315.
           05  WS-TXN-STATUS   PIC X(3)     VALUE 'PND'.
       01  WS-TOTALS.
           05  WS-TOT-DEBITS   PIC 9(10)V99 VALUE ZEROS.
           05  WS-TOT-CREDITS  PIC 9(10)V99 VALUE ZEROS.
           05  WS-TOT-COUNT    PIC 9(6)     VALUE ZEROS.
           05  WS-TOT-ERRORS   PIC 9(4)     VALUE ZEROS.
       01  WS-WORK-AREA        PIC X(50)    VALUE SPACES.
       01  WS-ERROR-MSG        PIC X(40)    VALUE SPACES.
       01  WS-RESET-FLAG       PIC X        VALUE 'Y'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'BEFORE RESET:'
           DISPLAY 'TXN-ID:   ' WS-TXN-ID
           DISPLAY 'AMOUNT:   ' WS-TXN-AMOUNT
           DISPLAY 'STATUS:   ' WS-TXN-STATUS
           IF WS-RESET-FLAG = 'Y'
               MOVE SPACES TO WS-TXN-ID
               MOVE SPACES TO WS-TXN-TYPE
               MOVE ZEROS  TO WS-TXN-AMOUNT
               MOVE ZEROS  TO WS-TXN-DATE
               MOVE SPACES TO WS-TXN-STATUS
               MOVE ZEROS  TO WS-TOT-DEBITS
               MOVE ZEROS  TO WS-TOT-CREDITS
               MOVE ZEROS  TO WS-TOT-COUNT
               MOVE ZEROS  TO WS-TOT-ERRORS
               MOVE SPACES TO WS-WORK-AREA
               MOVE SPACES TO WS-ERROR-MSG
           END-IF
           MOVE 'TXN-NEW00001' TO WS-TXN-ID
           MOVE 'CRED' TO WS-TXN-TYPE
           MOVE 2500.00 TO WS-TXN-AMOUNT
           MOVE 20240401 TO WS-TXN-DATE
           MOVE 'ACT' TO WS-TXN-STATUS
           DISPLAY 'AFTER RESET:'
           DISPLAY 'TXN-ID:   ' WS-TXN-ID
           DISPLAY 'AMOUNT:   ' WS-TXN-AMOUNT
           DISPLAY 'STATUS:   ' WS-TXN-STATUS
           STOP RUN.
