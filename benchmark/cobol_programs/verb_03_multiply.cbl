       IDENTIFICATION DIVISION.
       PROGRAM-ID. VERB-MULTIPLY.
      *---------------------------------------------------------------
      * MULTIPLY BY with GIVING - unit pricing and quantity
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ITEM-1-PRICE     PIC 9(5)V99  VALUE 24.99.
       01  WS-ITEM-1-QTY       PIC 9(4)     VALUE 150.
       01  WS-ITEM-2-PRICE     PIC 9(5)V99  VALUE 12.50.
       01  WS-ITEM-2-QTY       PIC 9(4)     VALUE 300.
       01  WS-ITEM-3-PRICE     PIC 9(5)V99  VALUE 89.95.
       01  WS-ITEM-3-QTY       PIC 9(4)     VALUE 45.
       01  WS-LINE-1-TOTAL     PIC 9(8)V99  VALUE ZEROS.
       01  WS-LINE-2-TOTAL     PIC 9(8)V99  VALUE ZEROS.
       01  WS-LINE-3-TOTAL     PIC 9(8)V99  VALUE ZEROS.
       01  WS-SUBTOTAL         PIC 9(9)V99  VALUE ZEROS.
       01  WS-TAX-RATE         PIC 9V9999   VALUE 0.1498.
       01  WS-TAX-AMOUNT       PIC 9(8)V99  VALUE ZEROS.
       01  WS-MARKUP-FACTOR    PIC 9V99     VALUE 1.35.
       01  WS-WHOLESALE-TOTAL  PIC 9(9)V99  VALUE ZEROS.
       01  WS-RETAIL-TOTAL     PIC 9(9)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MULTIPLY WS-ITEM-1-PRICE BY WS-ITEM-1-QTY
               GIVING WS-LINE-1-TOTAL
           MULTIPLY WS-ITEM-2-PRICE BY WS-ITEM-2-QTY
               GIVING WS-LINE-2-TOTAL
           MULTIPLY WS-ITEM-3-PRICE BY WS-ITEM-3-QTY
               GIVING WS-LINE-3-TOTAL
           ADD WS-LINE-1-TOTAL WS-LINE-2-TOTAL
               WS-LINE-3-TOTAL
               GIVING WS-SUBTOTAL
           MULTIPLY WS-SUBTOTAL BY WS-TAX-RATE
               GIVING WS-TAX-AMOUNT
           MOVE WS-SUBTOTAL TO WS-WHOLESALE-TOTAL
           MULTIPLY WS-SUBTOTAL BY WS-MARKUP-FACTOR
               GIVING WS-RETAIL-TOTAL
           DISPLAY 'LINE 1:     ' WS-LINE-1-TOTAL
           DISPLAY 'LINE 2:     ' WS-LINE-2-TOTAL
           DISPLAY 'LINE 3:     ' WS-LINE-3-TOTAL
           DISPLAY 'SUBTOTAL:   ' WS-SUBTOTAL
           DISPLAY 'TAX:        ' WS-TAX-AMOUNT
           DISPLAY 'WHOLESALE:  ' WS-WHOLESALE-TOTAL
           DISPLAY 'RETAIL:     ' WS-RETAIL-TOTAL
           STOP RUN.
