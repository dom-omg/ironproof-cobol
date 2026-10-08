       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMPOUND-OR-COND.
      *---------------------------------------------------------------
      * IF with OR conditions - transaction fraud detection
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TRANS-ID         PIC X(12)    VALUE 'TXN-00987654'.
       01  WS-TRANS-AMOUNT     PIC 9(8)V99  VALUE 15000.00.
       01  WS-TRANS-TYPE       PIC X(4)     VALUE 'WIRE'.
       01  WS-COUNTRY-CODE     PIC X(3)     VALUE 'CAN'.
       01  WS-HOUR-OF-DAY      PIC 9(2)     VALUE 3.
       01  WS-ACCT-AGE-DAYS    PIC 9(4)     VALUE 45.
       01  WS-PREV-TRANS-AMT   PIC 9(8)V99  VALUE 200.00.
       01  WS-FRAUD-FLAG       PIC X        VALUE 'N'.
       01  WS-FRAUD-REASON     PIC X(25)    VALUE SPACES.
       01  WS-RISK-SCORE       PIC 9(3)     VALUE ZEROS.
       01  WS-REVIEW-NEEDED    PIC X        VALUE 'N'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE ZEROS TO WS-RISK-SCORE
           IF WS-TRANS-AMOUNT > 10000
               OR WS-TRANS-TYPE = 'WIRE'
               OR WS-TRANS-TYPE = 'INTL'
               ADD 30 TO WS-RISK-SCORE
           END-IF
           IF WS-HOUR-OF-DAY < 5
               OR WS-HOUR-OF-DAY > 23
               ADD 20 TO WS-RISK-SCORE
           END-IF
           IF WS-ACCT-AGE-DAYS < 30
               OR WS-ACCT-AGE-DAYS < 90
               AND WS-TRANS-AMOUNT > 5000
               ADD 25 TO WS-RISK-SCORE
           END-IF
           IF WS-TRANS-AMOUNT > WS-PREV-TRANS-AMT * 50
               OR WS-TRANS-AMOUNT > 25000
               ADD 35 TO WS-RISK-SCORE
               MOVE 'AMOUNT ANOMALY' TO WS-FRAUD-REASON
           END-IF
           IF WS-COUNTRY-CODE = 'NGA'
               OR WS-COUNTRY-CODE = 'RUS'
               OR WS-COUNTRY-CODE = 'CHN'
               ADD 40 TO WS-RISK-SCORE
           END-IF
           IF WS-RISK-SCORE >= 80
               MOVE 'Y' TO WS-FRAUD-FLAG
               MOVE 'Y' TO WS-REVIEW-NEEDED
           ELSE IF WS-RISK-SCORE >= 50
               MOVE 'N' TO WS-FRAUD-FLAG
               MOVE 'Y' TO WS-REVIEW-NEEDED
           ELSE
               MOVE 'N' TO WS-FRAUD-FLAG
               MOVE 'N' TO WS-REVIEW-NEEDED
           END-IF
           DISPLAY 'TRANS:   ' WS-TRANS-ID
           DISPLAY 'SCORE:   ' WS-RISK-SCORE
           DISPLAY 'FRAUD:   ' WS-FRAUD-FLAG
           DISPLAY 'REVIEW:  ' WS-REVIEW-NEEDED
           DISPLAY 'REASON:  ' WS-FRAUD-REASON
           STOP RUN.
