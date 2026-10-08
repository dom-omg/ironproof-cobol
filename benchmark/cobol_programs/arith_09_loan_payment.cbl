       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOAN-PAYMENT.
      *---------------------------------------------------------------
      * Monthly loan payment calculation (amortization)
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-LOAN-AMOUNT      PIC 9(9)V99  VALUE 250000.00.
       01  WS-ANNUAL-RATE      PIC 9V9999   VALUE 0.0575.
       01  WS-TERM-YEARS       PIC 9(2)     VALUE 25.
       01  WS-MONTHLY-RATE     PIC 9V999999 VALUE ZEROS.
       01  WS-NUM-PAYMENTS     PIC 9(4)     VALUE ZEROS.
       01  WS-MONTHLY-PAYMENT  PIC 9(7)V99  VALUE ZEROS.
       01  WS-TOTAL-PAID       PIC 9(9)V99  VALUE ZEROS.
       01  WS-TOTAL-INTEREST   PIC 9(9)V99  VALUE ZEROS.
       01  WS-NUMERATOR        PIC 9(12)V999999 VALUE ZEROS.
       01  WS-DENOMINATOR      PIC 9(12)V999999 VALUE ZEROS.
       01  WS-POWER-FACTOR     PIC 9(12)V999999 VALUE ZEROS.
       01  WS-CTR              PIC 9(4)     VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-MONTHLY-RATE =
               WS-ANNUAL-RATE / 12
           COMPUTE WS-NUM-PAYMENTS =
               WS-TERM-YEARS * 12
           MOVE 1 TO WS-POWER-FACTOR
           MOVE 1 TO WS-CTR
           PERFORM CALC-POWER
               UNTIL WS-CTR > WS-NUM-PAYMENTS
           COMPUTE WS-NUMERATOR =
               WS-MONTHLY-RATE * WS-POWER-FACTOR
           COMPUTE WS-DENOMINATOR =
               WS-POWER-FACTOR - 1
           IF WS-DENOMINATOR > 0
               COMPUTE WS-MONTHLY-PAYMENT =
                   WS-LOAN-AMOUNT * WS-NUMERATOR
                   / WS-DENOMINATOR
           END-IF
           COMPUTE WS-TOTAL-PAID =
               WS-MONTHLY-PAYMENT * WS-NUM-PAYMENTS
           COMPUTE WS-TOTAL-INTEREST =
               WS-TOTAL-PAID - WS-LOAN-AMOUNT
           DISPLAY 'LOAN AMOUNT:     ' WS-LOAN-AMOUNT
           DISPLAY 'MONTHLY PAYMENT: ' WS-MONTHLY-PAYMENT
           DISPLAY 'TOTAL INTEREST:  ' WS-TOTAL-INTEREST
           STOP RUN.

       CALC-POWER.
           COMPUTE WS-POWER-FACTOR =
               WS-POWER-FACTOR * (1 + WS-MONTHLY-RATE)
           ADD 1 TO WS-CTR.
