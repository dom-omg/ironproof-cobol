       IDENTIFICATION DIVISION.
       PROGRAM-ID. DECIMAL-TRUNC-TEST.
      *---------------------------------------------------------------
      * Fixed-point decimal truncation stress test
      * Tests precision loss when PIC has limited decimal places
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PRICE          PIC 9(4)V99  VALUE 29.99.
       01  WS-QTY            PIC 9(3)     VALUE 3.
       01  WS-SUBTOTAL       PIC 9(6)V99  VALUE ZEROS.
       01  WS-TAX-RATE       PIC V9(4)    VALUE 0.0975.
       01  WS-TAX-AMT        PIC 9(4)V99  VALUE ZEROS.
       01  WS-TOTAL          PIC 9(6)V99  VALUE ZEROS.
       01  WS-THIRD          PIC 9(4)V99  VALUE ZEROS.
       01  WS-FULL-PREC      PIC 9(6)V9999 VALUE ZEROS.
       01  WS-TRUNC-PREC     PIC 9(6)V99  VALUE ZEROS.
       01  WS-AMOUNT         PIC 9(5)V99  VALUE 10000.00.
       01  WS-PARTS          PIC 9(2)     VALUE 7.
       01  WS-EACH-PART      PIC 9(5)V99  VALUE ZEROS.
       01  WS-LEFTOVER       PIC 9(5)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-SUBTOTAL = WS-PRICE * WS-QTY
           COMPUTE WS-TAX-AMT = WS-SUBTOTAL * WS-TAX-RATE
           COMPUTE WS-TOTAL = WS-SUBTOTAL + WS-TAX-AMT
           DIVIDE 1 BY 3 GIVING WS-THIRD
           COMPUTE WS-FULL-PREC = WS-PRICE * WS-TAX-RATE
           COMPUTE WS-TRUNC-PREC = WS-PRICE * WS-TAX-RATE
           DIVIDE WS-AMOUNT BY WS-PARTS
               GIVING WS-EACH-PART REMAINDER WS-LEFTOVER
           DISPLAY 'SUBTOTAL:      ' WS-SUBTOTAL
           DISPLAY 'TAX:           ' WS-TAX-AMT
           DISPLAY 'TOTAL:         ' WS-TOTAL
           DISPLAY 'THIRD:         ' WS-THIRD
           DISPLAY 'FULL PREC:     ' WS-FULL-PREC
           DISPLAY 'TRUNC PREC:    ' WS-TRUNC-PREC
           DISPLAY 'EACH PART:     ' WS-EACH-PART
           DISPLAY 'LEFTOVER:      ' WS-LEFTOVER
           STOP RUN.
