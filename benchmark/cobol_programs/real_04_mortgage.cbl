       IDENTIFICATION DIVISION.
       PROGRAM-ID. MORTGAGE-QUALIFY.
      *---------------------------------------------------------------
      * Mortgage qualification check - CMHC rules
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-APPLICATION.
           05  WS-APP-ID       PIC X(12)    VALUE 'MTG-20240315'.
           05  WS-PROPERTY-VAL PIC 9(9)V99  VALUE 525000.00.
           05  WS-DOWN-PAYMENT PIC 9(9)V99  VALUE 52500.00.
           05  WS-MORTGAGE-AMT PIC 9(9)V99  VALUE ZEROS.
           05  WS-AMORT-YEARS  PIC 9(2)     VALUE 25.
       01  WS-BORROWER.
           05  WS-GROSS-INCOME PIC 9(9)V99  VALUE 110000.00.
           05  WS-MONTHLY-INC  PIC 9(7)V99  VALUE ZEROS.
           05  WS-OTHER-DEBT   PIC 9(6)V99  VALUE 450.00.
           05  WS-CREDIT-SCORE PIC 9(3)     VALUE 740.
       01  WS-RATES.
           05  WS-POSTED-RATE  PIC 9V9999   VALUE 0.0579.
           05  WS-STRESS-RATE  PIC 9V9999   VALUE ZEROS.
           05  WS-STRESS-MIN   PIC 9V9999   VALUE 0.0525.
           05  WS-MONTHLY-RATE PIC 9V999999 VALUE ZEROS.
       01  WS-CALCULATIONS.
           05  WS-MONTHLY-PMT  PIC 9(7)V99  VALUE ZEROS.
           05  WS-PROPERTY-TAX PIC 9(6)V99  VALUE 350.00.
           05  WS-HEATING-COST PIC 9(4)V99  VALUE 125.00.
           05  WS-CMHC-PREMIUM PIC 9(7)V99  VALUE ZEROS.
           05  WS-CMHC-RATE    PIC 9V9999   VALUE ZEROS.
       01  WS-RATIOS.
           05  WS-GDS-RATIO    PIC 9V9999   VALUE ZEROS.
           05  WS-TDS-RATIO    PIC 9V9999   VALUE ZEROS.
           05  WS-LTV-RATIO    PIC 9V9999   VALUE ZEROS.
           05  WS-DOWN-PCT     PIC 9V9999   VALUE ZEROS.
       01  WS-RESULT.
           05  WS-QUALIFIED    PIC X        VALUE SPACES.
           05  WS-REASON       PIC X(30)    VALUE SPACES.
           05  WS-CMHC-NEEDED  PIC X        VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           PERFORM CALC-MORTGAGE-DETAILS
           PERFORM CALC-CMHC-INSURANCE
           PERFORM CALC-STRESS-TEST
           PERFORM CALC-RATIOS
           PERFORM CHECK-QUALIFICATION
           PERFORM DISPLAY-DECISION
           STOP RUN.

       CALC-MORTGAGE-DETAILS.
           COMPUTE WS-MORTGAGE-AMT =
               WS-PROPERTY-VAL - WS-DOWN-PAYMENT
           COMPUTE WS-MONTHLY-INC =
               WS-GROSS-INCOME / 12
           IF WS-PROPERTY-VAL > 0
               COMPUTE WS-DOWN-PCT =
                   WS-DOWN-PAYMENT / WS-PROPERTY-VAL
               COMPUTE WS-LTV-RATIO =
                   WS-MORTGAGE-AMT / WS-PROPERTY-VAL
           END-IF.

       CALC-CMHC-INSURANCE.
           IF WS-DOWN-PCT < 0.20
               MOVE 'Y' TO WS-CMHC-NEEDED
               EVALUATE TRUE
                   WHEN WS-LTV-RATIO <= 0.65
                       MOVE 0.0060 TO WS-CMHC-RATE
                   WHEN WS-LTV-RATIO <= 0.75
                       MOVE 0.0170 TO WS-CMHC-RATE
                   WHEN WS-LTV-RATIO <= 0.80
                       MOVE 0.0240 TO WS-CMHC-RATE
                   WHEN WS-LTV-RATIO <= 0.85
                       MOVE 0.0280 TO WS-CMHC-RATE
                   WHEN WS-LTV-RATIO <= 0.90
                       MOVE 0.0310 TO WS-CMHC-RATE
                   WHEN OTHER
                       MOVE 0.0400 TO WS-CMHC-RATE
               END-EVALUATE
               COMPUTE WS-CMHC-PREMIUM =
                   WS-MORTGAGE-AMT * WS-CMHC-RATE
               ADD WS-CMHC-PREMIUM TO WS-MORTGAGE-AMT
           ELSE
               MOVE 'N' TO WS-CMHC-NEEDED
               MOVE ZEROS TO WS-CMHC-PREMIUM
           END-IF.

       CALC-STRESS-TEST.
           COMPUTE WS-STRESS-RATE =
               WS-POSTED-RATE + 0.0200
           IF WS-STRESS-RATE < WS-STRESS-MIN
               MOVE WS-STRESS-MIN TO WS-STRESS-RATE
           END-IF
           COMPUTE WS-MONTHLY-RATE =
               WS-STRESS-RATE / 12
           COMPUTE WS-MONTHLY-PMT =
               WS-MORTGAGE-AMT * WS-MONTHLY-RATE
               / (1 - 1 / 1.005).

       CALC-RATIOS.
           IF WS-MONTHLY-INC > 0
               COMPUTE WS-GDS-RATIO =
                   (WS-MONTHLY-PMT + WS-PROPERTY-TAX
                    + WS-HEATING-COST)
                   / WS-MONTHLY-INC
               COMPUTE WS-TDS-RATIO =
                   (WS-MONTHLY-PMT + WS-PROPERTY-TAX
                    + WS-HEATING-COST + WS-OTHER-DEBT)
                   / WS-MONTHLY-INC
           END-IF.

       CHECK-QUALIFICATION.
           MOVE 'Y' TO WS-QUALIFIED
           IF WS-CREDIT-SCORE < 680
               MOVE 'N' TO WS-QUALIFIED
               MOVE 'CREDIT SCORE TOO LOW' TO WS-REASON
           END-IF
           IF WS-QUALIFIED = 'Y' AND WS-GDS-RATIO > 0.39
               MOVE 'N' TO WS-QUALIFIED
               MOVE 'GDS EXCEEDS 39%' TO WS-REASON
           END-IF
           IF WS-QUALIFIED = 'Y' AND WS-TDS-RATIO > 0.44
               MOVE 'N' TO WS-QUALIFIED
               MOVE 'TDS EXCEEDS 44%' TO WS-REASON
           END-IF
           IF WS-QUALIFIED = 'Y' AND WS-DOWN-PCT < 0.05
               MOVE 'N' TO WS-QUALIFIED
               MOVE 'DOWN PAYMENT < 5%' TO WS-REASON
           END-IF.

       DISPLAY-DECISION.
           DISPLAY '=== MORTGAGE DECISION ==='
           DISPLAY 'APPLICATION: ' WS-APP-ID
           DISPLAY 'PROPERTY:    ' WS-PROPERTY-VAL
           DISPLAY 'DOWN PMT:    ' WS-DOWN-PAYMENT
               ' (' WS-DOWN-PCT ')'
           DISPLAY 'MORTGAGE:    ' WS-MORTGAGE-AMT
           DISPLAY 'CMHC NEEDED: ' WS-CMHC-NEEDED
           DISPLAY 'CMHC PREM:   ' WS-CMHC-PREMIUM
           DISPLAY 'GDS:         ' WS-GDS-RATIO
           DISPLAY 'TDS:         ' WS-TDS-RATIO
           IF WS-QUALIFIED = 'Y'
               DISPLAY 'DECISION:    APPROVED'
           ELSE
               DISPLAY 'DECISION:    DECLINED'
               DISPLAY 'REASON:      ' WS-REASON
           END-IF.
