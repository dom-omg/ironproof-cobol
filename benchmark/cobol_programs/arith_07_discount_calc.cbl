       IDENTIFICATION DIVISION.
       PROGRAM-ID. DISCOUNT-CALC.
      *---------------------------------------------------------------
      * Tiered discount calculation based on purchase amount
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-CUSTOMER-ID      PIC X(8)     VALUE 'CUST0055'.
       01  WS-PURCHASE-AMT     PIC 9(7)V99  VALUE 2750.00.
       01  WS-LOYALTY-YEARS    PIC 9(2)     VALUE 5.
       01  WS-DISCOUNT-PCT     PIC 9V9999   VALUE ZEROS.
       01  WS-LOYALTY-BONUS    PIC 9V9999   VALUE ZEROS.
       01  WS-TOTAL-DISC-PCT   PIC 9V9999   VALUE ZEROS.
       01  WS-DISCOUNT-AMT     PIC 9(7)V99  VALUE ZEROS.
       01  WS-FINAL-AMOUNT     PIC 9(7)V99  VALUE ZEROS.
       01  WS-TIER             PIC X(10)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-PURCHASE-AMT >= 5000
                   MOVE 0.1500 TO WS-DISCOUNT-PCT
                   MOVE 'PLATINUM' TO WS-TIER
               WHEN WS-PURCHASE-AMT >= 2500
                   MOVE 0.1000 TO WS-DISCOUNT-PCT
                   MOVE 'GOLD' TO WS-TIER
               WHEN WS-PURCHASE-AMT >= 1000
                   MOVE 0.0500 TO WS-DISCOUNT-PCT
                   MOVE 'SILVER' TO WS-TIER
               WHEN WS-PURCHASE-AMT >= 500
                   MOVE 0.0250 TO WS-DISCOUNT-PCT
                   MOVE 'BRONZE' TO WS-TIER
               WHEN OTHER
                   MOVE ZEROS TO WS-DISCOUNT-PCT
                   MOVE 'STANDARD' TO WS-TIER
           END-EVALUATE
           IF WS-LOYALTY-YEARS >= 10
               MOVE 0.0300 TO WS-LOYALTY-BONUS
           ELSE IF WS-LOYALTY-YEARS >= 5
               MOVE 0.0150 TO WS-LOYALTY-BONUS
           ELSE
               MOVE ZEROS TO WS-LOYALTY-BONUS
           END-IF
           COMPUTE WS-TOTAL-DISC-PCT =
               WS-DISCOUNT-PCT + WS-LOYALTY-BONUS
           COMPUTE WS-DISCOUNT-AMT =
               WS-PURCHASE-AMT * WS-TOTAL-DISC-PCT
           COMPUTE WS-FINAL-AMOUNT =
               WS-PURCHASE-AMT - WS-DISCOUNT-AMT
           DISPLAY 'CUSTOMER:  ' WS-CUSTOMER-ID
           DISPLAY 'TIER:      ' WS-TIER
           DISPLAY 'DISCOUNT:  ' WS-DISCOUNT-AMT
           DISPLAY 'FINAL:     ' WS-FINAL-AMOUNT
           STOP RUN.
