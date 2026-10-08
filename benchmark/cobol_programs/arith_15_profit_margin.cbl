       IDENTIFICATION DIVISION.
       PROGRAM-ID. PROFIT-MARGIN.
      *---------------------------------------------------------------
      * Revenue - Cost = Profit, with margin percentage
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PRODUCT-CODE     PIC X(10)    VALUE 'PRD-A00142'.
       01  WS-UNITS-SOLD       PIC 9(6)     VALUE 1250.
       01  WS-UNIT-PRICE       PIC 9(5)V99  VALUE 89.99.
       01  WS-UNIT-COST        PIC 9(5)V99  VALUE 42.50.
       01  WS-FIXED-OVERHEAD   PIC 9(7)V99  VALUE 15000.00.
       01  WS-TOTAL-REVENUE    PIC 9(9)V99  VALUE ZEROS.
       01  WS-TOTAL-COGS       PIC 9(9)V99  VALUE ZEROS.
       01  WS-GROSS-PROFIT     PIC S9(9)V99 VALUE ZEROS.
       01  WS-NET-PROFIT       PIC S9(9)V99 VALUE ZEROS.
       01  WS-GROSS-MARGIN-PCT PIC S9(3)V99 VALUE ZEROS.
       01  WS-NET-MARGIN-PCT   PIC S9(3)V99 VALUE ZEROS.
       01  WS-PROFIT-STATUS    PIC X(10)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-TOTAL-REVENUE =
               WS-UNITS-SOLD * WS-UNIT-PRICE
           COMPUTE WS-TOTAL-COGS =
               WS-UNITS-SOLD * WS-UNIT-COST
           COMPUTE WS-GROSS-PROFIT =
               WS-TOTAL-REVENUE - WS-TOTAL-COGS
           COMPUTE WS-NET-PROFIT =
               WS-GROSS-PROFIT - WS-FIXED-OVERHEAD
           IF WS-TOTAL-REVENUE > 0
               COMPUTE WS-GROSS-MARGIN-PCT =
                   (WS-GROSS-PROFIT / WS-TOTAL-REVENUE) * 100
               COMPUTE WS-NET-MARGIN-PCT =
                   (WS-NET-PROFIT / WS-TOTAL-REVENUE) * 100
           END-IF
           IF WS-NET-PROFIT > 0
               MOVE 'PROFITABLE' TO WS-PROFIT-STATUS
           ELSE IF WS-NET-PROFIT = 0
               MOVE 'BREAK-EVEN' TO WS-PROFIT-STATUS
           ELSE
               MOVE 'LOSS' TO WS-PROFIT-STATUS
           END-IF
           DISPLAY 'PRODUCT:      ' WS-PRODUCT-CODE
           DISPLAY 'REVENUE:      ' WS-TOTAL-REVENUE
           DISPLAY 'COGS:         ' WS-TOTAL-COGS
           DISPLAY 'GROSS PROFIT: ' WS-GROSS-PROFIT
           DISPLAY 'NET PROFIT:   ' WS-NET-PROFIT
           DISPLAY 'GROSS MARGIN: ' WS-GROSS-MARGIN-PCT '%'
           DISPLAY 'NET MARGIN:   ' WS-NET-MARGIN-PCT '%'
           DISPLAY 'STATUS:       ' WS-PROFIT-STATUS
           STOP RUN.
