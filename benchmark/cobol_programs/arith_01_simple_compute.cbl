       IDENTIFICATION DIVISION.
       PROGRAM-ID. ARITH-SIMPLE-COMPUTE.
      *---------------------------------------------------------------
      * Basic COMPUTE with +, -, *, /
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-NUM-A            PIC 9(5)V99  VALUE 150.25.
       01  WS-NUM-B            PIC 9(5)V99  VALUE 75.50.
       01  WS-SUM              PIC 9(6)V99  VALUE ZEROS.
       01  WS-DIFFERENCE       PIC S9(6)V99 VALUE ZEROS.
       01  WS-PRODUCT          PIC 9(10)V99 VALUE ZEROS.
       01  WS-QUOTIENT         PIC 9(6)V99  VALUE ZEROS.
       01  WS-COMBINED         PIC S9(10)V99 VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-SUM = WS-NUM-A + WS-NUM-B
           COMPUTE WS-DIFFERENCE = WS-NUM-A - WS-NUM-B
           COMPUTE WS-PRODUCT = WS-NUM-A * WS-NUM-B
           IF WS-NUM-B > 0
               COMPUTE WS-QUOTIENT = WS-NUM-A / WS-NUM-B
           END-IF
           COMPUTE WS-COMBINED =
               (WS-NUM-A + WS-NUM-B) * 2 - WS-NUM-A / 3
           DISPLAY 'SUM:        ' WS-SUM
           DISPLAY 'DIFFERENCE: ' WS-DIFFERENCE
           DISPLAY 'PRODUCT:    ' WS-PRODUCT
           DISPLAY 'QUOTIENT:   ' WS-QUOTIENT
           DISPLAY 'COMBINED:   ' WS-COMBINED
           STOP RUN.
