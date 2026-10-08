       IDENTIFICATION DIVISION.
       PROGRAM-ID. TAX-BRACKET-CALC.
      *---------------------------------------------------------------
      * Quebec provincial tax bracket calculation (2024 rates)
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TAXABLE-INCOME   PIC 9(9)V99  VALUE 85000.00.
       01  WS-TAX-AMOUNT       PIC 9(9)V99  VALUE ZEROS.
       01  WS-BRACKET-1-LIMIT  PIC 9(9)V99  VALUE 49275.00.
       01  WS-BRACKET-2-LIMIT  PIC 9(9)V99  VALUE 98540.00.
       01  WS-BRACKET-3-LIMIT  PIC 9(9)V99  VALUE 119910.00.
       01  WS-RATE-1           PIC 9V9999   VALUE 0.1500.
       01  WS-RATE-2           PIC 9V9999   VALUE 0.2000.
       01  WS-RATE-3           PIC 9V9999   VALUE 0.2400.
       01  WS-RATE-4           PIC 9V9999   VALUE 0.2575.
       01  WS-EXCESS           PIC 9(9)V99  VALUE ZEROS.
       01  WS-TAX-BRACKET      PIC X(20)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-TAXABLE-INCOME <= WS-BRACKET-1-LIMIT
                   COMPUTE WS-TAX-AMOUNT =
                       WS-TAXABLE-INCOME * WS-RATE-1
                   MOVE 'BRACKET 1 - 15%' TO WS-TAX-BRACKET
               WHEN WS-TAXABLE-INCOME <= WS-BRACKET-2-LIMIT
                   COMPUTE WS-EXCESS =
                       WS-TAXABLE-INCOME - WS-BRACKET-1-LIMIT
                   COMPUTE WS-TAX-AMOUNT =
                       WS-BRACKET-1-LIMIT * WS-RATE-1
                       + WS-EXCESS * WS-RATE-2
                   MOVE 'BRACKET 2 - 20%' TO WS-TAX-BRACKET
               WHEN WS-TAXABLE-INCOME <= WS-BRACKET-3-LIMIT
                   COMPUTE WS-EXCESS =
                       WS-TAXABLE-INCOME - WS-BRACKET-2-LIMIT
                   COMPUTE WS-TAX-AMOUNT =
                       WS-BRACKET-1-LIMIT * WS-RATE-1
                       + (WS-BRACKET-2-LIMIT - WS-BRACKET-1-LIMIT)
                       * WS-RATE-2
                       + WS-EXCESS * WS-RATE-3
                   MOVE 'BRACKET 3 - 24%' TO WS-TAX-BRACKET
               WHEN OTHER
                   COMPUTE WS-EXCESS =
                       WS-TAXABLE-INCOME - WS-BRACKET-3-LIMIT
                   COMPUTE WS-TAX-AMOUNT =
                       WS-BRACKET-1-LIMIT * WS-RATE-1
                       + (WS-BRACKET-2-LIMIT - WS-BRACKET-1-LIMIT)
                       * WS-RATE-2
                       + (WS-BRACKET-3-LIMIT - WS-BRACKET-2-LIMIT)
                       * WS-RATE-3
                       + WS-EXCESS * WS-RATE-4
                   MOVE 'BRACKET 4 - 25.75%' TO WS-TAX-BRACKET
           END-EVALUATE
           DISPLAY 'INCOME:  ' WS-TAXABLE-INCOME
           DISPLAY 'TAX:     ' WS-TAX-AMOUNT
           DISPLAY 'BRACKET: ' WS-TAX-BRACKET
           STOP RUN.
