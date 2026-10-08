       IDENTIFICATION DIVISION.
       PROGRAM-ID. VERB-DIVIDE.
      *---------------------------------------------------------------
      * DIVIDE with GIVING and REMAINDER - inventory allocation
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TOTAL-UNITS      PIC 9(6)     VALUE 10000.
       01  WS-NUM-WAREHOUSES   PIC 9(2)     VALUE 7.
       01  WS-UNITS-PER-WH     PIC 9(5)     VALUE ZEROS.
       01  WS-REMAINDER-UNITS  PIC 9(4)     VALUE ZEROS.
       01  WS-TOTAL-COST       PIC 9(9)V99  VALUE 85000.00.
       01  WS-UNIT-COST        PIC 9(5)V99  VALUE ZEROS.
       01  WS-DAILY-TARGET     PIC 9(6)     VALUE 5000.
       01  WS-WORK-DAYS        PIC 9(2)     VALUE 22.
       01  WS-DAILY-RATE       PIC 9(5)V99  VALUE ZEROS.
       01  WS-DAILY-REMAINDER  PIC 9(4)     VALUE ZEROS.
       01  WS-REVENUE          PIC 9(9)V99  VALUE 120000.00.
       01  WS-SHARES           PIC 9(3)     VALUE 4.
       01  WS-SHARE-AMOUNT     PIC 9(8)V99  VALUE ZEROS.
       01  WS-SHARE-REMAIN     PIC 9(5)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-NUM-WAREHOUSES > 0
               DIVIDE WS-TOTAL-UNITS BY WS-NUM-WAREHOUSES
                   GIVING WS-UNITS-PER-WH
                   REMAINDER WS-REMAINDER-UNITS
           END-IF
           IF WS-TOTAL-UNITS > 0
               DIVIDE WS-TOTAL-COST BY WS-TOTAL-UNITS
                   GIVING WS-UNIT-COST
           END-IF
           IF WS-WORK-DAYS > 0
               DIVIDE WS-DAILY-TARGET BY WS-WORK-DAYS
                   GIVING WS-DAILY-RATE
                   REMAINDER WS-DAILY-REMAINDER
           END-IF
           IF WS-SHARES > 0
               DIVIDE WS-REVENUE BY WS-SHARES
                   GIVING WS-SHARE-AMOUNT
                   REMAINDER WS-SHARE-REMAIN
           END-IF
           DISPLAY 'TOTAL UNITS:   ' WS-TOTAL-UNITS
           DISPLAY 'WAREHOUSES:    ' WS-NUM-WAREHOUSES
           DISPLAY 'UNITS/WH:      ' WS-UNITS-PER-WH
           DISPLAY 'REMAINDER:     ' WS-REMAINDER-UNITS
           DISPLAY 'UNIT COST:     ' WS-UNIT-COST
           DISPLAY 'DAILY RATE:    ' WS-DAILY-RATE
           DISPLAY 'DAILY REMAIN:  ' WS-DAILY-REMAINDER
           DISPLAY 'SHARE AMOUNT:  ' WS-SHARE-AMOUNT
           DISPLAY 'SHARE REMAIN:  ' WS-SHARE-REMAIN
           STOP RUN.
