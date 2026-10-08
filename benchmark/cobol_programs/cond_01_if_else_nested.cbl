       IDENTIFICATION DIVISION.
       PROGRAM-ID. IF-ELSE-NESTED.
      *---------------------------------------------------------------
      * Nested IF/ELSE 3 levels deep - credit approval
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-APPLICANT-ID     PIC X(10)    VALUE 'APP-007821'.
       01  WS-CREDIT-SCORE     PIC 9(3)     VALUE 720.
       01  WS-ANNUAL-INCOME    PIC 9(9)V99  VALUE 65000.00.
       01  WS-DEBT-RATIO       PIC 9V99     VALUE 0.32.
       01  WS-EMPLOYMENT-YRS   PIC 9(2)     VALUE 4.
       01  WS-APPROVAL-STATUS  PIC X(12)    VALUE SPACES.
       01  WS-CREDIT-LIMIT     PIC 9(7)V99  VALUE ZEROS.
       01  WS-INTEREST-RATE    PIC 9V9999   VALUE ZEROS.
       01  WS-RISK-FLAG        PIC X        VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-CREDIT-SCORE >= 700
               IF WS-ANNUAL-INCOME >= 50000
                   IF WS-DEBT-RATIO <= 0.35
                       MOVE 'APPROVED' TO WS-APPROVAL-STATUS
                       COMPUTE WS-CREDIT-LIMIT =
                           WS-ANNUAL-INCOME * 0.30
                       MOVE 0.0599 TO WS-INTEREST-RATE
                       MOVE 'L' TO WS-RISK-FLAG
                   ELSE
                       MOVE 'CONDITIONAL' TO WS-APPROVAL-STATUS
                       COMPUTE WS-CREDIT-LIMIT =
                           WS-ANNUAL-INCOME * 0.15
                       MOVE 0.0899 TO WS-INTEREST-RATE
                       MOVE 'M' TO WS-RISK-FLAG
                   END-IF
               ELSE
                   IF WS-EMPLOYMENT-YRS >= 3
                       MOVE 'CONDITIONAL' TO WS-APPROVAL-STATUS
                       COMPUTE WS-CREDIT-LIMIT =
                           WS-ANNUAL-INCOME * 0.20
                       MOVE 0.0799 TO WS-INTEREST-RATE
                       MOVE 'M' TO WS-RISK-FLAG
                   ELSE
                       MOVE 'DECLINED' TO WS-APPROVAL-STATUS
                       MOVE ZEROS TO WS-CREDIT-LIMIT
                       MOVE ZEROS TO WS-INTEREST-RATE
                       MOVE 'H' TO WS-RISK-FLAG
                   END-IF
               END-IF
           ELSE
               IF WS-CREDIT-SCORE >= 600
                   IF WS-ANNUAL-INCOME >= 75000
                       MOVE 'CONDITIONAL' TO WS-APPROVAL-STATUS
                       COMPUTE WS-CREDIT-LIMIT =
                           WS-ANNUAL-INCOME * 0.10
                       MOVE 0.1299 TO WS-INTEREST-RATE
                       MOVE 'M' TO WS-RISK-FLAG
                   ELSE
                       MOVE 'DECLINED' TO WS-APPROVAL-STATUS
                       MOVE ZEROS TO WS-CREDIT-LIMIT
                       MOVE ZEROS TO WS-INTEREST-RATE
                       MOVE 'H' TO WS-RISK-FLAG
                   END-IF
               ELSE
                   MOVE 'DECLINED' TO WS-APPROVAL-STATUS
                   MOVE ZEROS TO WS-CREDIT-LIMIT
                   MOVE ZEROS TO WS-INTEREST-RATE
                   MOVE 'H' TO WS-RISK-FLAG
               END-IF
           END-IF
           DISPLAY 'APPLICANT: ' WS-APPLICANT-ID
           DISPLAY 'STATUS:    ' WS-APPROVAL-STATUS
           DISPLAY 'LIMIT:     ' WS-CREDIT-LIMIT
           DISPLAY 'RATE:      ' WS-INTEREST-RATE
           DISPLAY 'RISK:      ' WS-RISK-FLAG
           STOP RUN.
