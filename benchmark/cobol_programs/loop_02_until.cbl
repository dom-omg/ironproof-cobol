       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOOP-UNTIL.
      *---------------------------------------------------------------
      * PERFORM UNTIL condition - find break-even point
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-FIXED-COSTS      PIC 9(8)V99  VALUE 50000.00.
       01  WS-UNIT-PRICE       PIC 9(5)V99  VALUE 29.99.
       01  WS-UNIT-COST        PIC 9(5)V99  VALUE 12.50.
       01  WS-CONTRIB-MARGIN   PIC 9(5)V99  VALUE ZEROS.
       01  WS-UNITS-SOLD       PIC 9(6)     VALUE ZEROS.
       01  WS-TOTAL-REVENUE    PIC 9(9)V99  VALUE ZEROS.
       01  WS-TOTAL-COST       PIC 9(9)V99  VALUE ZEROS.
       01  WS-PROFIT           PIC S9(9)V99 VALUE ZEROS.
       01  WS-BREAK-EVEN-FLAG  PIC X        VALUE 'N'.
       01  WS-INCREMENT        PIC 9(4)     VALUE 100.
       01  WS-MAX-UNITS        PIC 9(6)     VALUE 50000.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-CONTRIB-MARGIN =
               WS-UNIT-PRICE - WS-UNIT-COST
           MOVE ZEROS TO WS-UNITS-SOLD
           PERFORM CALC-PROFIT
               UNTIL WS-PROFIT >= 0
               OR WS-UNITS-SOLD >= WS-MAX-UNITS
           IF WS-PROFIT >= 0
               MOVE 'Y' TO WS-BREAK-EVEN-FLAG
           END-IF
           DISPLAY 'FIXED COSTS:    ' WS-FIXED-COSTS
           DISPLAY 'UNIT PRICE:     ' WS-UNIT-PRICE
           DISPLAY 'UNIT COST:      ' WS-UNIT-COST
           DISPLAY 'MARGIN/UNIT:    ' WS-CONTRIB-MARGIN
           DISPLAY 'BREAK-EVEN AT:  ' WS-UNITS-SOLD ' UNITS'
           DISPLAY 'REVENUE:        ' WS-TOTAL-REVENUE
           DISPLAY 'TOTAL COST:     ' WS-TOTAL-COST
           DISPLAY 'PROFIT:         ' WS-PROFIT
           DISPLAY 'FOUND:          ' WS-BREAK-EVEN-FLAG
           STOP RUN.

       CALC-PROFIT.
           ADD WS-INCREMENT TO WS-UNITS-SOLD
           COMPUTE WS-TOTAL-REVENUE =
               WS-UNITS-SOLD * WS-UNIT-PRICE
           COMPUTE WS-TOTAL-COST =
               WS-FIXED-COSTS + (WS-UNITS-SOLD * WS-UNIT-COST)
           COMPUTE WS-PROFIT =
               WS-TOTAL-REVENUE - WS-TOTAL-COST.
