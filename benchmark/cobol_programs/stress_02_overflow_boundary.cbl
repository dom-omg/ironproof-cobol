       IDENTIFICATION DIVISION.
       PROGRAM-ID. OVERFLOW-TEST.
      *---------------------------------------------------------------
      * PIC overflow boundary stress test
      * Tests what happens when computations exceed PIC capacity
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SMALL          PIC 9(2)     VALUE 95.
       01  WS-ADD-AMT        PIC 9(2)     VALUE 10.
       01  WS-OVERFLOW-SUM   PIC 9(2)     VALUE ZEROS.
       01  WS-SAFE-SUM       PIC 9(4)     VALUE ZEROS.
       01  WS-PCT-A          PIC 9(2)V99  VALUE 33.33.
       01  WS-PCT-B          PIC 9(2)V99  VALUE 33.33.
       01  WS-PCT-C          PIC 9(2)V99  VALUE 33.34.
       01  WS-TOTAL-PCT      PIC 9(2)V99  VALUE ZEROS.
       01  WS-BALANCE        PIC 9(3)V99  VALUE 990.00.
       01  WS-DEPOSIT        PIC 9(3)V99  VALUE 15.50.
       01  WS-NEW-BAL        PIC 9(3)V99  VALUE ZEROS.
       01  WS-COUNTER        PIC 9(2)     VALUE ZEROS.
       01  WS-LIMIT          PIC 9(2)     VALUE 50.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-OVERFLOW-SUM = WS-SMALL + WS-ADD-AMT
           COMPUTE WS-SAFE-SUM = WS-SMALL + WS-ADD-AMT
           COMPUTE WS-TOTAL-PCT =
               WS-PCT-A + WS-PCT-B + WS-PCT-C
           COMPUTE WS-NEW-BAL = WS-BALANCE + WS-DEPOSIT
           PERFORM ACCUMULATE-LOOP
           DISPLAY 'OVERFLOW SUM:  ' WS-OVERFLOW-SUM
           DISPLAY 'SAFE SUM:      ' WS-SAFE-SUM
           DISPLAY 'TOTAL PCT:     ' WS-TOTAL-PCT
           DISPLAY 'NEW BALANCE:   ' WS-NEW-BAL
           DISPLAY 'COUNTER:       ' WS-COUNTER
           STOP RUN.

       ACCUMULATE-LOOP.
           PERFORM UNTIL WS-COUNTER >= WS-LIMIT
               ADD 1 TO WS-COUNTER
           END-PERFORM.
