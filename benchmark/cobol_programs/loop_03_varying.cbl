       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOOP-VARYING.
      *---------------------------------------------------------------
      * PERFORM VARYING - tax table generation
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INCOME-LEVEL     PIC 9(7)V99  VALUE ZEROS.
       01  WS-START-INCOME     PIC 9(7)V99  VALUE 20000.00.
       01  WS-END-INCOME       PIC 9(7)V99  VALUE 120000.00.
       01  WS-INCOME-STEP      PIC 9(5)V99  VALUE 10000.00.
       01  WS-TAX-AMOUNT       PIC 9(7)V99  VALUE ZEROS.
       01  WS-EFF-RATE         PIC 9V9999   VALUE ZEROS.
       01  WS-NET-INCOME       PIC 9(7)V99  VALUE ZEROS.
       01  WS-BRACKET          PIC X(8)     VALUE SPACES.
       01  WS-ROW-COUNT        PIC 9(3)     VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           DISPLAY 'INCOME TAX TABLE'
           DISPLAY '================================'
           MOVE ZEROS TO WS-ROW-COUNT
           PERFORM CALC-TAX-ROW
               VARYING WS-INCOME-LEVEL
               FROM WS-START-INCOME
               BY WS-INCOME-STEP
               UNTIL WS-INCOME-LEVEL > WS-END-INCOME
           DISPLAY '================================'
           DISPLAY 'TOTAL ROWS: ' WS-ROW-COUNT
           STOP RUN.

       CALC-TAX-ROW.
           ADD 1 TO WS-ROW-COUNT
           EVALUATE TRUE
               WHEN WS-INCOME-LEVEL <= 49275
                   COMPUTE WS-TAX-AMOUNT =
                       WS-INCOME-LEVEL * 0.15
                   MOVE 'TIER 1' TO WS-BRACKET
               WHEN WS-INCOME-LEVEL <= 98540
                   COMPUTE WS-TAX-AMOUNT =
                       49275 * 0.15
                       + (WS-INCOME-LEVEL - 49275) * 0.20
                   MOVE 'TIER 2' TO WS-BRACKET
               WHEN OTHER
                   COMPUTE WS-TAX-AMOUNT =
                       49275 * 0.15
                       + (98540 - 49275) * 0.20
                       + (WS-INCOME-LEVEL - 98540) * 0.24
                   MOVE 'TIER 3' TO WS-BRACKET
           END-EVALUATE
           IF WS-INCOME-LEVEL > 0
               COMPUTE WS-EFF-RATE =
                   WS-TAX-AMOUNT / WS-INCOME-LEVEL
           END-IF
           COMPUTE WS-NET-INCOME =
               WS-INCOME-LEVEL - WS-TAX-AMOUNT
           DISPLAY WS-BRACKET ' | '
               'INCOME: ' WS-INCOME-LEVEL ' | '
               'TAX: ' WS-TAX-AMOUNT ' | '
               'NET: ' WS-NET-INCOME.
