       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMPOUND-INTEREST.
      *---------------------------------------------------------------
      * Compound interest calculation
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PRINCIPAL        PIC 9(9)V99  VALUE 10000.00.
       01  WS-ANNUAL-RATE      PIC 9V9999   VALUE 0.0525.
       01  WS-PERIODS          PIC 9(3)     VALUE 12.
       01  WS-YEARS            PIC 9(2)     VALUE 5.
       01  WS-TOTAL-PERIODS    PIC 9(5)     VALUE ZEROS.
       01  WS-PERIOD-RATE      PIC 9V999999 VALUE ZEROS.
       01  WS-FUTURE-VALUE     PIC 9(12)V99 VALUE ZEROS.
       01  WS-INTEREST-EARNED  PIC 9(12)V99 VALUE ZEROS.
       01  WS-COUNTER          PIC 9(5)     VALUE ZEROS.
       01  WS-CURRENT-AMOUNT   PIC 9(12)V99 VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-TOTAL-PERIODS = WS-PERIODS * WS-YEARS
           COMPUTE WS-PERIOD-RATE =
               WS-ANNUAL-RATE / WS-PERIODS
           MOVE WS-PRINCIPAL TO WS-CURRENT-AMOUNT
           MOVE 1 TO WS-COUNTER
           PERFORM COMPOUND-LOOP
               UNTIL WS-COUNTER > WS-TOTAL-PERIODS
           MOVE WS-CURRENT-AMOUNT TO WS-FUTURE-VALUE
           COMPUTE WS-INTEREST-EARNED =
               WS-FUTURE-VALUE - WS-PRINCIPAL
           DISPLAY 'PRINCIPAL:     ' WS-PRINCIPAL
           DISPLAY 'ANNUAL RATE:   ' WS-ANNUAL-RATE
           DISPLAY 'PERIODS/YEAR:  ' WS-PERIODS
           DISPLAY 'YEARS:         ' WS-YEARS
           DISPLAY 'FUTURE VALUE:  ' WS-FUTURE-VALUE
           DISPLAY 'INTEREST:      ' WS-INTEREST-EARNED
           STOP RUN.

       COMPOUND-LOOP.
           COMPUTE WS-CURRENT-AMOUNT =
               WS-CURRENT-AMOUNT * (1 + WS-PERIOD-RATE)
           ADD 1 TO WS-COUNTER.
