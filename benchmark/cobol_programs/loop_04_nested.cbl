       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOOP-NESTED.
      *---------------------------------------------------------------
      * Nested PERFORM - quarterly sales by region
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-REGION-IDX       PIC 9        VALUE ZEROS.
       01  WS-QUARTER-IDX      PIC 9        VALUE ZEROS.
       01  WS-NUM-REGIONS      PIC 9        VALUE 4.
       01  WS-NUM-QUARTERS     PIC 9        VALUE 4.
       01  WS-BASE-SALES       PIC 9(7)V99  VALUE 50000.00.
       01  WS-REGION-MULT      PIC 9V99     VALUE ZEROS.
       01  WS-QUARTER-MULT     PIC 9V99     VALUE ZEROS.
       01  WS-QUARTERLY-SALES  PIC 9(8)V99  VALUE ZEROS.
       01  WS-REGION-TOTAL     PIC 9(9)V99  VALUE ZEROS.
       01  WS-GRAND-TOTAL      PIC 9(10)V99 VALUE ZEROS.
       01  WS-REGION-NAME      PIC X(10)    VALUE SPACES.
       01  WS-QUARTER-NAME     PIC X(3)     VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE ZEROS TO WS-GRAND-TOTAL
           PERFORM PROCESS-REGION
               VARYING WS-REGION-IDX FROM 1 BY 1
               UNTIL WS-REGION-IDX > WS-NUM-REGIONS
           DISPLAY '=========================='
           DISPLAY 'GRAND TOTAL: ' WS-GRAND-TOTAL
           STOP RUN.

       PROCESS-REGION.
           EVALUATE WS-REGION-IDX
               WHEN 1
                   MOVE 'EAST' TO WS-REGION-NAME
                   MOVE 1.20 TO WS-REGION-MULT
               WHEN 2
                   MOVE 'WEST' TO WS-REGION-NAME
                   MOVE 0.95 TO WS-REGION-MULT
               WHEN 3
                   MOVE 'NORTH' TO WS-REGION-NAME
                   MOVE 0.80 TO WS-REGION-MULT
               WHEN 4
                   MOVE 'SOUTH' TO WS-REGION-NAME
                   MOVE 1.10 TO WS-REGION-MULT
           END-EVALUATE
           MOVE ZEROS TO WS-REGION-TOTAL
           PERFORM PROCESS-QUARTER
               VARYING WS-QUARTER-IDX FROM 1 BY 1
               UNTIL WS-QUARTER-IDX > WS-NUM-QUARTERS
           ADD WS-REGION-TOTAL TO WS-GRAND-TOTAL
           DISPLAY WS-REGION-NAME ' TOTAL: ' WS-REGION-TOTAL.

       PROCESS-QUARTER.
           EVALUATE WS-QUARTER-IDX
               WHEN 1
                   MOVE 'Q1 ' TO WS-QUARTER-NAME
                   MOVE 0.85 TO WS-QUARTER-MULT
               WHEN 2
                   MOVE 'Q2 ' TO WS-QUARTER-NAME
                   MOVE 1.00 TO WS-QUARTER-MULT
               WHEN 3
                   MOVE 'Q3 ' TO WS-QUARTER-NAME
                   MOVE 0.90 TO WS-QUARTER-MULT
               WHEN 4
                   MOVE 'Q4 ' TO WS-QUARTER-NAME
                   MOVE 1.25 TO WS-QUARTER-MULT
           END-EVALUATE
           COMPUTE WS-QUARTERLY-SALES =
               WS-BASE-SALES * WS-REGION-MULT
               * WS-QUARTER-MULT
           ADD WS-QUARTERLY-SALES TO WS-REGION-TOTAL.
