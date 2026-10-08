       IDENTIFICATION DIVISION.
       PROGRAM-ID. CURRENCY-CONVERT.
      *---------------------------------------------------------------
      * Multi-currency conversion (CAD base)
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT-CAD       PIC 9(9)V99  VALUE 5000.00.
       01  WS-RATE-USD         PIC 9V999999 VALUE 0.741200.
       01  WS-RATE-EUR         PIC 9V999999 VALUE 0.682500.
       01  WS-RATE-GBP         PIC 9V999999 VALUE 0.585300.
       01  WS-RATE-JPY         PIC 9(3)V99  VALUE 110.25.
       01  WS-AMOUNT-USD       PIC 9(9)V99  VALUE ZEROS.
       01  WS-AMOUNT-EUR       PIC 9(9)V99  VALUE ZEROS.
       01  WS-AMOUNT-GBP       PIC 9(9)V99  VALUE ZEROS.
       01  WS-AMOUNT-JPY       PIC 9(12)V99 VALUE ZEROS.
       01  WS-CURRENCY-CODE    PIC X(3)     VALUE 'USD'.
       01  WS-CONVERTED        PIC 9(12)V99 VALUE ZEROS.
       01  WS-FEE-RATE         PIC 9V9999   VALUE 0.0150.
       01  WS-FEE-AMOUNT       PIC 9(6)V99  VALUE ZEROS.
       01  WS-NET-CONVERTED    PIC 9(12)V99 VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-AMOUNT-USD = WS-AMOUNT-CAD * WS-RATE-USD
           COMPUTE WS-AMOUNT-EUR = WS-AMOUNT-CAD * WS-RATE-EUR
           COMPUTE WS-AMOUNT-GBP = WS-AMOUNT-CAD * WS-RATE-GBP
           COMPUTE WS-AMOUNT-JPY = WS-AMOUNT-CAD * WS-RATE-JPY
           EVALUATE WS-CURRENCY-CODE
               WHEN 'USD'
                   MOVE WS-AMOUNT-USD TO WS-CONVERTED
               WHEN 'EUR'
                   MOVE WS-AMOUNT-EUR TO WS-CONVERTED
               WHEN 'GBP'
                   MOVE WS-AMOUNT-GBP TO WS-CONVERTED
               WHEN 'JPY'
                   MOVE WS-AMOUNT-JPY TO WS-CONVERTED
               WHEN OTHER
                   MOVE ZEROS TO WS-CONVERTED
           END-EVALUATE
           COMPUTE WS-FEE-AMOUNT = WS-CONVERTED * WS-FEE-RATE
           COMPUTE WS-NET-CONVERTED =
               WS-CONVERTED - WS-FEE-AMOUNT
           DISPLAY 'CAD AMOUNT:  ' WS-AMOUNT-CAD
           DISPLAY 'CURRENCY:    ' WS-CURRENCY-CODE
           DISPLAY 'CONVERTED:   ' WS-CONVERTED
           DISPLAY 'FEE:         ' WS-FEE-AMOUNT
           DISPLAY 'NET AMOUNT:  ' WS-NET-CONVERTED
           STOP RUN.
