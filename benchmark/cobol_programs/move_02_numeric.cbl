       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE-NUMERIC.
      *---------------------------------------------------------------
      * MOVE numeric literals - account balance initialization
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ACCT-NUM         PIC X(12)    VALUE '200045678901'.
       01  WS-OPENING-BAL      PIC 9(9)V99  VALUE ZEROS.
       01  WS-CREDIT-LIMIT     PIC 9(7)V99  VALUE ZEROS.
       01  WS-MIN-BALANCE      PIC 9(5)V99  VALUE ZEROS.
       01  WS-INTEREST-RATE    PIC 9V9999   VALUE ZEROS.
       01  WS-MONTHLY-FEE      PIC 9(3)V99  VALUE ZEROS.
       01  WS-OVERDRAFT-FEE    PIC 9(3)V99  VALUE ZEROS.
       01  WS-ACCT-TYPE        PIC X        VALUE SPACES.
       01  WS-TRANS-LIMIT      PIC 9(3)     VALUE ZEROS.
       01  WS-DAILY-LIMIT      PIC 9(6)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE 'C' TO WS-ACCT-TYPE
           MOVE 5000.00 TO WS-OPENING-BAL
           MOVE 25000.00 TO WS-CREDIT-LIMIT
           MOVE 1000.00 TO WS-MIN-BALANCE
           MOVE 0.0225 TO WS-INTEREST-RATE
           MOVE 4.95 TO WS-MONTHLY-FEE
           MOVE 45.00 TO WS-OVERDRAFT-FEE
           MOVE 100 TO WS-TRANS-LIMIT
           MOVE 5000.00 TO WS-DAILY-LIMIT
           IF WS-ACCT-TYPE = 'P'
               MOVE 0.00 TO WS-MONTHLY-FEE
               MOVE 200 TO WS-TRANS-LIMIT
               MOVE 10000.00 TO WS-DAILY-LIMIT
           END-IF
           DISPLAY 'ACCOUNT:   ' WS-ACCT-NUM
           DISPLAY 'TYPE:      ' WS-ACCT-TYPE
           DISPLAY 'BALANCE:   ' WS-OPENING-BAL
           DISPLAY 'CREDIT:    ' WS-CREDIT-LIMIT
           DISPLAY 'MIN BAL:   ' WS-MIN-BALANCE
           DISPLAY 'RATE:      ' WS-INTEREST-RATE
           DISPLAY 'FEE:       ' WS-MONTHLY-FEE
           DISPLAY 'OD FEE:    ' WS-OVERDRAFT-FEE
           DISPLAY 'DAILY LMT: ' WS-DAILY-LIMIT
           STOP RUN.
