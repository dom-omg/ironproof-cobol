       IDENTIFICATION DIVISION.
       PROGRAM-ID. INVENTORY-REORDER.
      *---------------------------------------------------------------
      * Inventory reorder point calculation with safety stock
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PRODUCT.
           05  WS-SKU          PIC X(10)    VALUE 'SKU-A01234'.
           05  WS-DESCRIPTION  PIC X(25)    VALUE 'HYDRAULIC PUMP ASSEMBLY'.
           05  WS-CATEGORY     PIC X(3)     VALUE 'MFG'.
       01  WS-INVENTORY.
           05  WS-QTY-ON-HAND  PIC 9(6)     VALUE 150.
           05  WS-QTY-ON-ORDER PIC 9(6)     VALUE 0.
           05  WS-QTY-RESERVED PIC 9(6)     VALUE 25.
           05  WS-QTY-AVAILABLE PIC S9(6)   VALUE ZEROS.
       01  WS-DEMAND.
           05  WS-DAILY-AVG    PIC 9(4)V99  VALUE 12.50.
           05  WS-DAILY-STDDEV PIC 9(3)V99  VALUE 3.75.
           05  WS-LEAD-DAYS    PIC 9(3)     VALUE 14.
           05  WS-LEAD-STDDEV  PIC 9(2)V9   VALUE 2.5.
       01  WS-CALCULATIONS.
           05  WS-SAFETY-STOCK PIC 9(5)     VALUE ZEROS.
           05  WS-REORDER-PT   PIC 9(5)     VALUE ZEROS.
           05  WS-EOQ          PIC 9(6)     VALUE ZEROS.
           05  WS-LEAD-DEMAND  PIC 9(6)V99  VALUE ZEROS.
           05  WS-SERVICE-LVL  PIC 9V99     VALUE 1.65.
       01  WS-COSTS.
           05  WS-UNIT-COST    PIC 9(5)V99  VALUE 245.00.
           05  WS-ORDER-COST   PIC 9(4)V99  VALUE 150.00.
           05  WS-HOLDING-RATE PIC 9V99     VALUE 0.25.
           05  WS-HOLDING-COST PIC 9(5)V99  VALUE ZEROS.
           05  WS-ANNUAL-DEMAND PIC 9(7)    VALUE ZEROS.
       01  WS-RESULT.
           05  WS-REORDER-FLAG PIC X        VALUE SPACES.
           05  WS-ORDER-QTY    PIC 9(6)     VALUE ZEROS.
           05  WS-URGENCY      PIC X(10)    VALUE SPACES.
       01  WS-EOQ-NUMERATOR    PIC 9(12)V99 VALUE ZEROS.
       01  WS-EOQ-DENOM        PIC 9(6)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           PERFORM CALC-AVAILABLE
           PERFORM CALC-SAFETY-STOCK
           PERFORM CALC-REORDER-POINT
           PERFORM CALC-EOQ
           PERFORM CHECK-REORDER
           PERFORM DISPLAY-STATUS
           STOP RUN.

       CALC-AVAILABLE.
           COMPUTE WS-QTY-AVAILABLE =
               WS-QTY-ON-HAND + WS-QTY-ON-ORDER
               - WS-QTY-RESERVED.

       CALC-SAFETY-STOCK.
           COMPUTE WS-SAFETY-STOCK =
               WS-SERVICE-LVL * WS-DAILY-STDDEV
               * WS-LEAD-DAYS.

       CALC-REORDER-POINT.
           COMPUTE WS-LEAD-DEMAND =
               WS-DAILY-AVG * WS-LEAD-DAYS
           COMPUTE WS-REORDER-PT =
               WS-LEAD-DEMAND + WS-SAFETY-STOCK.

       CALC-EOQ.
           COMPUTE WS-ANNUAL-DEMAND =
               WS-DAILY-AVG * 365
           COMPUTE WS-HOLDING-COST =
               WS-UNIT-COST * WS-HOLDING-RATE
           IF WS-HOLDING-COST > 0
               COMPUTE WS-EOQ-NUMERATOR =
                   2 * WS-ANNUAL-DEMAND * WS-ORDER-COST
               COMPUTE WS-EOQ-DENOM = WS-HOLDING-COST
               COMPUTE WS-EOQ =
                   WS-EOQ-NUMERATOR / WS-EOQ-DENOM
           END-IF.

       CHECK-REORDER.
           IF WS-QTY-AVAILABLE <= WS-SAFETY-STOCK
               MOVE 'Y' TO WS-REORDER-FLAG
               MOVE 'CRITICAL' TO WS-URGENCY
               MOVE WS-EOQ TO WS-ORDER-QTY
               IF WS-ORDER-QTY < WS-REORDER-PT
                   MOVE WS-REORDER-PT TO WS-ORDER-QTY
               END-IF
           ELSE IF WS-QTY-AVAILABLE <= WS-REORDER-PT
               MOVE 'Y' TO WS-REORDER-FLAG
               MOVE 'STANDARD' TO WS-URGENCY
               MOVE WS-EOQ TO WS-ORDER-QTY
           ELSE
               MOVE 'N' TO WS-REORDER-FLAG
               MOVE 'NONE' TO WS-URGENCY
               MOVE ZEROS TO WS-ORDER-QTY
           END-IF.

       DISPLAY-STATUS.
           DISPLAY '=== INVENTORY STATUS ==='
           DISPLAY 'SKU:          ' WS-SKU
           DISPLAY 'DESCRIPTION:  ' WS-DESCRIPTION
           DISPLAY 'ON HAND:      ' WS-QTY-ON-HAND
           DISPLAY 'AVAILABLE:    ' WS-QTY-AVAILABLE
           DISPLAY 'SAFETY STOCK: ' WS-SAFETY-STOCK
           DISPLAY 'REORDER PT:   ' WS-REORDER-PT
           DISPLAY 'EOQ:          ' WS-EOQ
           DISPLAY 'REORDER:      ' WS-REORDER-FLAG
           DISPLAY 'URGENCY:      ' WS-URGENCY
           IF WS-REORDER-FLAG = 'Y'
               DISPLAY 'ORDER QTY:    ' WS-ORDER-QTY
           END-IF.
