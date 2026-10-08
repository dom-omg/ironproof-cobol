       IDENTIFICATION DIVISION.
       PROGRAM-ID. SHIPPING-COST.
      *---------------------------------------------------------------
      * Shipping cost calculation by weight tiers and zones
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ORDER-ID         PIC X(10)    VALUE 'ORD-045821'.
       01  WS-WEIGHT-KG        PIC 9(4)V99  VALUE 12.75.
       01  WS-ZONE-CODE        PIC X(2)     VALUE 'B '.
       01  WS-BASE-RATE        PIC 9(4)V99  VALUE ZEROS.
       01  WS-WEIGHT-CHARGE    PIC 9(5)V99  VALUE ZEROS.
       01  WS-ZONE-MULT        PIC 9V99     VALUE ZEROS.
       01  WS-FUEL-SURCHARGE   PIC 9(4)V99  VALUE ZEROS.
       01  WS-INSURANCE        PIC 9(4)V99  VALUE ZEROS.
       01  WS-TOTAL-SHIPPING   PIC 9(5)V99  VALUE ZEROS.
       01  WS-FUEL-RATE        PIC 9V9999   VALUE 0.0850.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-WEIGHT-KG <= 1.00
                   MOVE 8.50 TO WS-BASE-RATE
               WHEN WS-WEIGHT-KG <= 5.00
                   MOVE 12.00 TO WS-BASE-RATE
                   COMPUTE WS-WEIGHT-CHARGE =
                       (WS-WEIGHT-KG - 1) * 1.50
               WHEN WS-WEIGHT-KG <= 15.00
                   MOVE 18.00 TO WS-BASE-RATE
                   COMPUTE WS-WEIGHT-CHARGE =
                       (WS-WEIGHT-KG - 5) * 1.20
               WHEN WS-WEIGHT-KG <= 30.00
                   MOVE 25.00 TO WS-BASE-RATE
                   COMPUTE WS-WEIGHT-CHARGE =
                       (WS-WEIGHT-KG - 15) * 0.95
               WHEN OTHER
                   MOVE 35.00 TO WS-BASE-RATE
                   COMPUTE WS-WEIGHT-CHARGE =
                       (WS-WEIGHT-KG - 30) * 0.75
           END-EVALUATE
           EVALUATE WS-ZONE-CODE
               WHEN 'A'
                   MOVE 1.00 TO WS-ZONE-MULT
               WHEN 'B'
                   MOVE 1.25 TO WS-ZONE-MULT
               WHEN 'C'
                   MOVE 1.50 TO WS-ZONE-MULT
               WHEN 'D'
                   MOVE 2.00 TO WS-ZONE-MULT
               WHEN OTHER
                   MOVE 2.50 TO WS-ZONE-MULT
           END-EVALUATE
           COMPUTE WS-TOTAL-SHIPPING =
               (WS-BASE-RATE + WS-WEIGHT-CHARGE) * WS-ZONE-MULT
           COMPUTE WS-FUEL-SURCHARGE =
               WS-TOTAL-SHIPPING * WS-FUEL-RATE
           COMPUTE WS-INSURANCE = WS-WEIGHT-KG * 0.25
           COMPUTE WS-TOTAL-SHIPPING =
               WS-TOTAL-SHIPPING + WS-FUEL-SURCHARGE
               + WS-INSURANCE
           DISPLAY 'ORDER:    ' WS-ORDER-ID
           DISPLAY 'WEIGHT:   ' WS-WEIGHT-KG ' KG'
           DISPLAY 'ZONE:     ' WS-ZONE-CODE
           DISPLAY 'SHIPPING: ' WS-TOTAL-SHIPPING
           STOP RUN.
