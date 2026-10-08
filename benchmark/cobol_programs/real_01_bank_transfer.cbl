       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANK-TRANSFER.
      *---------------------------------------------------------------
      * Bank transfer with full validation - interac e-transfer
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-FROM-ACCT        PIC X(10)    VALUE '1000456789'.
       01  WS-TO-ACCT          PIC X(10)    VALUE '2000987654'.
       01  WS-TRANSFER-AMT     PIC 9(7)V99  VALUE 2500.00.
       01  WS-FROM-BALANCE     PIC S9(11)V99 VALUE 15000.00.
       01  WS-TO-BALANCE       PIC S9(11)V99 VALUE 3200.00.
       01  WS-FROM-STATUS      PIC X(2)     VALUE 'AC'.
       01  WS-TO-STATUS        PIC X(2)     VALUE 'AC'.
       01  WS-DAILY-LIMIT      PIC 9(7)V99  VALUE 10000.00.
       01  WS-DAILY-USED       PIC 9(7)V99  VALUE 1500.00.
       01  WS-DAILY-REMAINING  PIC 9(7)V99  VALUE ZEROS.
       01  WS-TRANSFER-FEE     PIC 9(3)V99  VALUE ZEROS.
       01  WS-TOTAL-DEBIT      PIC 9(7)V99  VALUE ZEROS.
       01  WS-NEW-FROM-BAL     PIC S9(11)V99 VALUE ZEROS.
       01  WS-NEW-TO-BAL       PIC S9(11)V99 VALUE ZEROS.
       01  WS-VALID            PIC X        VALUE 'Y'.
       01  WS-ERROR-CODE       PIC 9(4)     VALUE ZEROS.
       01  WS-ERROR-MSG        PIC X(30)    VALUE SPACES.
       01  WS-TRANS-REF        PIC X(15)    VALUE 'TRF-20240315-01'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           PERFORM VALIDATE-TRANSFER
           IF WS-VALID = 'Y'
               PERFORM EXECUTE-TRANSFER
           END-IF
           PERFORM DISPLAY-RESULT
           STOP RUN.

       VALIDATE-TRANSFER.
           IF WS-FROM-ACCT = WS-TO-ACCT
               MOVE 'N' TO WS-VALID
               MOVE 1001 TO WS-ERROR-CODE
               MOVE 'SAME ACCOUNT TRANSFER' TO WS-ERROR-MSG
           END-IF
           IF WS-VALID = 'Y' AND WS-FROM-STATUS NOT = 'AC'
               MOVE 'N' TO WS-VALID
               MOVE 1002 TO WS-ERROR-CODE
               MOVE 'SOURCE ACCT INACTIVE' TO WS-ERROR-MSG
           END-IF
           IF WS-VALID = 'Y' AND WS-TO-STATUS NOT = 'AC'
               MOVE 'N' TO WS-VALID
               MOVE 1003 TO WS-ERROR-CODE
               MOVE 'DEST ACCT INACTIVE' TO WS-ERROR-MSG
           END-IF
           IF WS-VALID = 'Y' AND WS-TRANSFER-AMT <= 0
               MOVE 'N' TO WS-VALID
               MOVE 1004 TO WS-ERROR-CODE
               MOVE 'INVALID AMOUNT' TO WS-ERROR-MSG
           END-IF
           IF WS-VALID = 'Y'
               IF WS-TRANSFER-AMT > 1000
                   MOVE 1.50 TO WS-TRANSFER-FEE
               ELSE
                   MOVE ZEROS TO WS-TRANSFER-FEE
               END-IF
               COMPUTE WS-TOTAL-DEBIT =
                   WS-TRANSFER-AMT + WS-TRANSFER-FEE
               IF WS-TOTAL-DEBIT > WS-FROM-BALANCE
                   MOVE 'N' TO WS-VALID
                   MOVE 1005 TO WS-ERROR-CODE
                   MOVE 'INSUFFICIENT FUNDS' TO WS-ERROR-MSG
               END-IF
           END-IF
           IF WS-VALID = 'Y'
               COMPUTE WS-DAILY-REMAINING =
                   WS-DAILY-LIMIT - WS-DAILY-USED
               IF WS-TRANSFER-AMT > WS-DAILY-REMAINING
                   MOVE 'N' TO WS-VALID
                   MOVE 1006 TO WS-ERROR-CODE
                   MOVE 'DAILY LIMIT EXCEEDED' TO WS-ERROR-MSG
               END-IF
           END-IF.

       EXECUTE-TRANSFER.
           COMPUTE WS-NEW-FROM-BAL =
               WS-FROM-BALANCE - WS-TOTAL-DEBIT
           COMPUTE WS-NEW-TO-BAL =
               WS-TO-BALANCE + WS-TRANSFER-AMT
           MOVE 0 TO WS-ERROR-CODE.

       DISPLAY-RESULT.
           DISPLAY 'TRANSFER REF: ' WS-TRANS-REF
           DISPLAY 'FROM ACCT:    ' WS-FROM-ACCT
           DISPLAY 'TO ACCT:      ' WS-TO-ACCT
           DISPLAY 'AMOUNT:       ' WS-TRANSFER-AMT
           DISPLAY 'FEE:          ' WS-TRANSFER-FEE
           IF WS-VALID = 'Y'
               DISPLAY 'STATUS: COMPLETED'
               DISPLAY 'NEW FROM BAL: ' WS-NEW-FROM-BAL
               DISPLAY 'NEW TO BAL:   ' WS-NEW-TO-BAL
           ELSE
               DISPLAY 'STATUS: REJECTED'
               DISPLAY 'ERROR:  ' WS-ERROR-CODE
                   ' - ' WS-ERROR-MSG
           END-IF.
