       IDENTIFICATION DIVISION.
       PROGRAM-ID. VERB-ADD.
      *---------------------------------------------------------------
      * ADD with TO and GIVING - daily sales totals
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SALE-1           PIC 9(5)V99  VALUE 125.50.
       01  WS-SALE-2           PIC 9(5)V99  VALUE 89.99.
       01  WS-SALE-3           PIC 9(5)V99  VALUE 245.00.
       01  WS-SALE-4           PIC 9(5)V99  VALUE 67.25.
       01  WS-SALE-5           PIC 9(5)V99  VALUE 312.75.
       01  WS-RUNNING-TOTAL    PIC 9(7)V99  VALUE ZEROS.
       01  WS-MORNING-TOTAL    PIC 9(7)V99  VALUE ZEROS.
       01  WS-AFTERNOON-TOTAL  PIC 9(7)V99  VALUE ZEROS.
       01  WS-DAILY-TOTAL      PIC 9(7)V99  VALUE ZEROS.
       01  WS-TAX-AMOUNT       PIC 9(6)V99  VALUE ZEROS.
       01  WS-TAX-RATE         PIC 9V9999   VALUE 0.1498.
       01  WS-GRAND-TOTAL      PIC 9(7)V99  VALUE ZEROS.
       01  WS-TRANS-COUNT      PIC 9(4)     VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           ADD WS-SALE-1 TO WS-RUNNING-TOTAL
           ADD 1 TO WS-TRANS-COUNT
           ADD WS-SALE-2 TO WS-RUNNING-TOTAL
           ADD 1 TO WS-TRANS-COUNT
           ADD WS-SALE-3 TO WS-RUNNING-TOTAL
           ADD 1 TO WS-TRANS-COUNT
           ADD WS-SALE-1 WS-SALE-2 WS-SALE-3
               GIVING WS-MORNING-TOTAL
           ADD WS-SALE-4 WS-SALE-5
               GIVING WS-AFTERNOON-TOTAL
           ADD WS-SALE-4 TO WS-RUNNING-TOTAL
           ADD 1 TO WS-TRANS-COUNT
           ADD WS-SALE-5 TO WS-RUNNING-TOTAL
           ADD 1 TO WS-TRANS-COUNT
           ADD WS-MORNING-TOTAL WS-AFTERNOON-TOTAL
               GIVING WS-DAILY-TOTAL
           COMPUTE WS-TAX-AMOUNT =
               WS-DAILY-TOTAL * WS-TAX-RATE
           ADD WS-DAILY-TOTAL WS-TAX-AMOUNT
               GIVING WS-GRAND-TOTAL
           DISPLAY 'MORNING:   ' WS-MORNING-TOTAL
           DISPLAY 'AFTERNOON: ' WS-AFTERNOON-TOTAL
           DISPLAY 'DAILY:     ' WS-DAILY-TOTAL
           DISPLAY 'TAX:       ' WS-TAX-AMOUNT
           DISPLAY 'GRAND:     ' WS-GRAND-TOTAL
           DISPLAY 'TRANS CNT: ' WS-TRANS-COUNT
           STOP RUN.
