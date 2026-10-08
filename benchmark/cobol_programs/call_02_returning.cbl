       IDENTIFICATION DIVISION.
       PROGRAM-ID. CALL-RETURNING.
      *---------------------------------------------------------------
      * CALL with RETURNING - credit score lookup and rate calc
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SIN-NUMBER       PIC X(9)     VALUE '123456789'.
       01  WS-CREDIT-SCORE     PIC 9(3)     VALUE ZEROS.
       01  WS-LOOKUP-STATUS    PIC 9(4)     VALUE ZEROS.
       01  WS-LOAN-REQUEST.
           05  WS-LR-AMOUNT    PIC 9(9)V99  VALUE 350000.00.
           05  WS-LR-TERM      PIC 9(2)     VALUE 25.
           05  WS-LR-TYPE      PIC X(4)     VALUE 'MORT'.
       01  WS-RATE-RESULT.
           05  WS-RR-RATE      PIC 9V9999   VALUE ZEROS.
           05  WS-RR-APPROVED  PIC X        VALUE SPACES.
           05  WS-RR-MONTHLY   PIC 9(7)V99  VALUE ZEROS.
           05  WS-RR-TOTAL     PIC 9(9)V99  VALUE ZEROS.
       01  WS-RETURN-VALUE     PIC 9(4)     VALUE ZEROS.
       01  WS-RISK-PREMIUM     PIC 9V9999   VALUE ZEROS.
       01  WS-FINAL-RATE       PIC 9V9999   VALUE ZEROS.
       01  WS-BASE-RATE        PIC 9V9999   VALUE 0.0475.

       PROCEDURE DIVISION.
       MAIN-PARA.
           CALL 'CREDCHK' USING WS-SIN-NUMBER
                                WS-CREDIT-SCORE
               RETURNING WS-LOOKUP-STATUS
           IF WS-LOOKUP-STATUS = 0
               DISPLAY 'CREDIT SCORE: ' WS-CREDIT-SCORE
               EVALUATE TRUE
                   WHEN WS-CREDIT-SCORE >= 800
                       MOVE 0.0000 TO WS-RISK-PREMIUM
                   WHEN WS-CREDIT-SCORE >= 720
                       MOVE 0.0025 TO WS-RISK-PREMIUM
                   WHEN WS-CREDIT-SCORE >= 680
                       MOVE 0.0075 TO WS-RISK-PREMIUM
                   WHEN WS-CREDIT-SCORE >= 620
                       MOVE 0.0150 TO WS-RISK-PREMIUM
                   WHEN OTHER
                       MOVE 0.0300 TO WS-RISK-PREMIUM
               END-EVALUATE
               COMPUTE WS-FINAL-RATE =
                   WS-BASE-RATE + WS-RISK-PREMIUM
               MOVE WS-FINAL-RATE TO WS-RR-RATE
               CALL 'LOANCLC' USING WS-LOAN-REQUEST
                                    WS-RR-RATE
                   RETURNING WS-RETURN-VALUE
               IF WS-RETURN-VALUE = 0
                   MOVE 'Y' TO WS-RR-APPROVED
               ELSE
                   MOVE 'N' TO WS-RR-APPROVED
               END-IF
           ELSE
               DISPLAY 'CREDIT CHECK FAILED: '
                   WS-LOOKUP-STATUS
               MOVE 'N' TO WS-RR-APPROVED
           END-IF
           DISPLAY 'SIN:       ' WS-SIN-NUMBER
           DISPLAY 'SCORE:     ' WS-CREDIT-SCORE
           DISPLAY 'RATE:      ' WS-FINAL-RATE
           DISPLAY 'APPROVED:  ' WS-RR-APPROVED
           DISPLAY 'LOAN AMT:  ' WS-LR-AMOUNT
           STOP RUN.
