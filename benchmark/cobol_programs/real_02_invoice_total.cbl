       IDENTIFICATION DIVISION.
       PROGRAM-ID. INVOICE-TOTAL.
      *---------------------------------------------------------------
      * Invoice with line items, tax, discount (Quebec GST+QST)
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INVOICE-NUM      PIC X(12)    VALUE 'INV-2024-0312'.
       01  WS-CUSTOMER-ID      PIC X(10)    VALUE 'CLT-004521'.
       01  WS-INVOICE-DATE     PIC X(10)    VALUE '2024-03-15'.
       01  WS-LINE-ITEMS.
           05  WS-ITEM OCCURS 5 TIMES.
               10  WS-ITEM-DESC   PIC X(20).
               10  WS-ITEM-QTY    PIC 9(4).
               10  WS-ITEM-PRICE  PIC 9(5)V99.
               10  WS-ITEM-TOTAL  PIC 9(7)V99.
       01  WS-IDX              PIC 9        VALUE ZEROS.
       01  WS-SUBTOTAL         PIC 9(8)V99  VALUE ZEROS.
       01  WS-DISCOUNT-PCT     PIC 9V9999   VALUE 0.0500.
       01  WS-DISCOUNT-AMT     PIC 9(7)V99  VALUE ZEROS.
       01  WS-AFTER-DISCOUNT   PIC 9(8)V99  VALUE ZEROS.
       01  WS-GST-RATE         PIC 9V9999   VALUE 0.0500.
       01  WS-QST-RATE         PIC 9V9999   VALUE 0.0998.
       01  WS-GST-AMT          PIC 9(6)V99  VALUE ZEROS.
       01  WS-QST-AMT          PIC 9(6)V99  VALUE ZEROS.
       01  WS-TOTAL-TAX        PIC 9(7)V99  VALUE ZEROS.
       01  WS-INVOICE-TOTAL    PIC 9(9)V99  VALUE ZEROS.
       01  WS-NUM-ITEMS        PIC 9        VALUE 5.

       PROCEDURE DIVISION.
       MAIN-PARA.
           PERFORM INIT-ITEMS
           MOVE ZEROS TO WS-SUBTOTAL
           PERFORM CALC-LINE-TOTALS
               VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-NUM-ITEMS
           IF WS-SUBTOTAL >= 5000
               MOVE 0.1000 TO WS-DISCOUNT-PCT
           ELSE IF WS-SUBTOTAL >= 2000
               MOVE 0.0500 TO WS-DISCOUNT-PCT
           ELSE
               MOVE 0.0000 TO WS-DISCOUNT-PCT
           END-IF
           COMPUTE WS-DISCOUNT-AMT =
               WS-SUBTOTAL * WS-DISCOUNT-PCT
           COMPUTE WS-AFTER-DISCOUNT =
               WS-SUBTOTAL - WS-DISCOUNT-AMT
           COMPUTE WS-GST-AMT =
               WS-AFTER-DISCOUNT * WS-GST-RATE
           COMPUTE WS-QST-AMT =
               WS-AFTER-DISCOUNT * WS-QST-RATE
           COMPUTE WS-TOTAL-TAX =
               WS-GST-AMT + WS-QST-AMT
           COMPUTE WS-INVOICE-TOTAL =
               WS-AFTER-DISCOUNT + WS-TOTAL-TAX
           DISPLAY 'INVOICE:   ' WS-INVOICE-NUM
           DISPLAY 'CUSTOMER:  ' WS-CUSTOMER-ID
           DISPLAY 'SUBTOTAL:  ' WS-SUBTOTAL
           DISPLAY 'DISCOUNT:  ' WS-DISCOUNT-AMT
           DISPLAY 'GST:       ' WS-GST-AMT
           DISPLAY 'QST:       ' WS-QST-AMT
           DISPLAY 'TOTAL:     ' WS-INVOICE-TOTAL
           STOP RUN.

       INIT-ITEMS.
           MOVE 'SERVER RACK UNIT' TO WS-ITEM-DESC(1)
           MOVE 2 TO WS-ITEM-QTY(1)
           MOVE 1250.00 TO WS-ITEM-PRICE(1)
           MOVE 'CAT6 CABLE 100FT' TO WS-ITEM-DESC(2)
           MOVE 10 TO WS-ITEM-QTY(2)
           MOVE 45.99 TO WS-ITEM-PRICE(2)
           MOVE 'SSD 1TB NVME' TO WS-ITEM-DESC(3)
           MOVE 4 TO WS-ITEM-QTY(3)
           MOVE 189.99 TO WS-ITEM-PRICE(3)
           MOVE 'UPS 1500VA' TO WS-ITEM-DESC(4)
           MOVE 1 TO WS-ITEM-QTY(4)
           MOVE 425.00 TO WS-ITEM-PRICE(4)
           MOVE 'PATCH PANEL 48PT' TO WS-ITEM-DESC(5)
           MOVE 2 TO WS-ITEM-QTY(5)
           MOVE 175.00 TO WS-ITEM-PRICE(5).

       CALC-LINE-TOTALS.
           COMPUTE WS-ITEM-TOTAL(WS-IDX) =
               WS-ITEM-QTY(WS-IDX)
               * WS-ITEM-PRICE(WS-IDX)
           ADD WS-ITEM-TOTAL(WS-IDX) TO WS-SUBTOTAL.
