       IDENTIFICATION DIVISION.
       PROGRAM-ID. ELIGIBILITY-CHECK.
      *---------------------------------------------------------------
      * Multi-criteria eligibility check - mortgage pre-approval
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-CLIENT-ID        PIC X(10)    VALUE 'CLT-009876'.
       01  WS-GROSS-INCOME     PIC 9(9)V99  VALUE 95000.00.
       01  WS-MONTHLY-DEBT     PIC 9(6)V99  VALUE 1200.00.
       01  WS-DOWN-PAYMENT     PIC 9(9)V99  VALUE 60000.00.
       01  WS-PROPERTY-VALUE   PIC 9(9)V99  VALUE 450000.00.
       01  WS-CREDIT-SCORE     PIC 9(3)     VALUE 745.
       01  WS-EMPLOYMENT-TYPE  PIC X        VALUE 'S'.
       01  WS-YEARS-EMPLOYED   PIC 9(2)     VALUE 5.
       01  WS-GDS-RATIO        PIC 9V9999   VALUE ZEROS.
       01  WS-TDS-RATIO        PIC 9V9999   VALUE ZEROS.
       01  WS-LTV-RATIO        PIC 9V9999   VALUE ZEROS.
       01  WS-MONTHLY-INCOME   PIC 9(7)V99  VALUE ZEROS.
       01  WS-LOAN-AMOUNT      PIC 9(9)V99  VALUE ZEROS.
       01  WS-ELIGIBLE         PIC X        VALUE SPACES.
       01  WS-DENIAL-REASON    PIC X(25)    VALUE SPACES.
       01  WS-EST-PAYMENT      PIC 9(6)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-LOAN-AMOUNT =
               WS-PROPERTY-VALUE - WS-DOWN-PAYMENT
           COMPUTE WS-MONTHLY-INCOME =
               WS-GROSS-INCOME / 12
           COMPUTE WS-EST-PAYMENT =
               WS-LOAN-AMOUNT * 0.005
           IF WS-MONTHLY-INCOME > 0
               COMPUTE WS-GDS-RATIO =
                   WS-EST-PAYMENT / WS-MONTHLY-INCOME
               COMPUTE WS-TDS-RATIO =
                   (WS-EST-PAYMENT + WS-MONTHLY-DEBT)
                   / WS-MONTHLY-INCOME
           END-IF
           IF WS-PROPERTY-VALUE > 0
               COMPUTE WS-LTV-RATIO =
                   WS-LOAN-AMOUNT / WS-PROPERTY-VALUE
           END-IF
           MOVE 'Y' TO WS-ELIGIBLE
           IF WS-CREDIT-SCORE < 680
               MOVE 'N' TO WS-ELIGIBLE
               MOVE 'LOW CREDIT SCORE' TO WS-DENIAL-REASON
           END-IF
           IF WS-GDS-RATIO > 0.32 AND WS-ELIGIBLE = 'Y'
               MOVE 'N' TO WS-ELIGIBLE
               MOVE 'GDS RATIO TOO HIGH' TO WS-DENIAL-REASON
           END-IF
           IF WS-TDS-RATIO > 0.44 AND WS-ELIGIBLE = 'Y'
               MOVE 'N' TO WS-ELIGIBLE
               MOVE 'TDS RATIO TOO HIGH' TO WS-DENIAL-REASON
           END-IF
           IF WS-LTV-RATIO > 0.95 AND WS-ELIGIBLE = 'Y'
               MOVE 'N' TO WS-ELIGIBLE
               MOVE 'LTV TOO HIGH' TO WS-DENIAL-REASON
           END-IF
           IF WS-EMPLOYMENT-TYPE = 'S'
               AND WS-YEARS-EMPLOYED < 2
               AND WS-ELIGIBLE = 'Y'
               MOVE 'N' TO WS-ELIGIBLE
               MOVE 'SELF-EMP < 2 YEARS' TO WS-DENIAL-REASON
           END-IF
           DISPLAY 'CLIENT:   ' WS-CLIENT-ID
           DISPLAY 'ELIGIBLE: ' WS-ELIGIBLE
           DISPLAY 'GDS:      ' WS-GDS-RATIO
           DISPLAY 'TDS:      ' WS-TDS-RATIO
           DISPLAY 'LTV:      ' WS-LTV-RATIO
           IF WS-ELIGIBLE = 'N'
               DISPLAY 'REASON:   ' WS-DENIAL-REASON
           END-IF
           STOP RUN.
