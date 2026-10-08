       IDENTIFICATION DIVISION.
       PROGRAM-ID. NOT-CONDITION-DEMO.
      *---------------------------------------------------------------
      * NOT conditions - account validation checks
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ACCOUNT-NUM      PIC X(12)    VALUE '100045678901'.
       01  WS-ACCT-STATUS      PIC X        VALUE 'A'.
       01  WS-BALANCE          PIC S9(9)V99 VALUE 2500.00.
       01  WS-OVERDRAFT-LIMIT  PIC 9(5)V99  VALUE 500.00.
       01  WS-FROZEN-FLAG      PIC X        VALUE 'N'.
       01  WS-KYC-COMPLETE     PIC X        VALUE 'Y'.
       01  WS-VALID-ACCOUNT    PIC X        VALUE SPACES.
       01  WS-CAN-WITHDRAW     PIC X        VALUE SPACES.
       01  WS-ERROR-MSG        PIC X(30)    VALUE SPACES.
       01  WS-WITHDRAW-AMT     PIC 9(7)V99  VALUE 1000.00.
       01  WS-AVAIL-BALANCE    PIC S9(9)V99 VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE 'Y' TO WS-VALID-ACCOUNT
           IF NOT WS-ACCT-STATUS = 'A'
               MOVE 'N' TO WS-VALID-ACCOUNT
               MOVE 'ACCOUNT NOT ACTIVE' TO WS-ERROR-MSG
           END-IF
           IF NOT WS-FROZEN-FLAG = 'N'
               MOVE 'N' TO WS-VALID-ACCOUNT
               MOVE 'ACCOUNT FROZEN' TO WS-ERROR-MSG
           END-IF
           IF NOT WS-KYC-COMPLETE = 'Y'
               MOVE 'N' TO WS-VALID-ACCOUNT
               MOVE 'KYC INCOMPLETE' TO WS-ERROR-MSG
           END-IF
           IF WS-VALID-ACCOUNT NOT = 'N'
               COMPUTE WS-AVAIL-BALANCE =
                   WS-BALANCE + WS-OVERDRAFT-LIMIT
               IF NOT WS-WITHDRAW-AMT > WS-AVAIL-BALANCE
                   MOVE 'Y' TO WS-CAN-WITHDRAW
                   MOVE SPACES TO WS-ERROR-MSG
               ELSE
                   MOVE 'N' TO WS-CAN-WITHDRAW
                   MOVE 'INSUFFICIENT FUNDS' TO WS-ERROR-MSG
               END-IF
           ELSE
               MOVE 'N' TO WS-CAN-WITHDRAW
           END-IF
           DISPLAY 'ACCOUNT:   ' WS-ACCOUNT-NUM
           DISPLAY 'VALID:     ' WS-VALID-ACCOUNT
           DISPLAY 'WITHDRAW:  ' WS-CAN-WITHDRAW
           DISPLAY 'AVAILABLE: ' WS-AVAIL-BALANCE
           DISPLAY 'ERROR:     ' WS-ERROR-MSG
           STOP RUN.
