       IDENTIFICATION DIVISION.
       PROGRAM-ID. SALES-COMMISSION.
      *---------------------------------------------------------------
      * Sales commission calculation with tiered rates
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SALES-REP        PIC X(8)     VALUE 'REP00312'.
       01  WS-MONTHLY-SALES    PIC 9(8)V99  VALUE 125000.00.
       01  WS-QUOTA            PIC 9(8)V99  VALUE 80000.00.
       01  WS-TIER1-LIMIT      PIC 9(8)V99  VALUE 50000.00.
       01  WS-TIER2-LIMIT      PIC 9(8)V99  VALUE 100000.00.
       01  WS-RATE-TIER1       PIC 9V9999   VALUE 0.0300.
       01  WS-RATE-TIER2       PIC 9V9999   VALUE 0.0500.
       01  WS-RATE-TIER3       PIC 9V9999   VALUE 0.0800.
       01  WS-COMMISSION       PIC 9(7)V99  VALUE ZEROS.
       01  WS-QUOTA-BONUS      PIC 9(7)V99  VALUE ZEROS.
       01  WS-TOTAL-COMP       PIC 9(7)V99  VALUE ZEROS.
       01  WS-EXCESS           PIC 9(8)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-MONTHLY-SALES <= WS-TIER1-LIMIT
               COMPUTE WS-COMMISSION =
                   WS-MONTHLY-SALES * WS-RATE-TIER1
           ELSE IF WS-MONTHLY-SALES <= WS-TIER2-LIMIT
               COMPUTE WS-EXCESS =
                   WS-MONTHLY-SALES - WS-TIER1-LIMIT
               COMPUTE WS-COMMISSION =
                   WS-TIER1-LIMIT * WS-RATE-TIER1
                   + WS-EXCESS * WS-RATE-TIER2
           ELSE
               COMPUTE WS-EXCESS =
                   WS-MONTHLY-SALES - WS-TIER2-LIMIT
               COMPUTE WS-COMMISSION =
                   WS-TIER1-LIMIT * WS-RATE-TIER1
                   + (WS-TIER2-LIMIT - WS-TIER1-LIMIT)
                   * WS-RATE-TIER2
                   + WS-EXCESS * WS-RATE-TIER3
           END-IF
           IF WS-MONTHLY-SALES >= WS-QUOTA
               COMPUTE WS-QUOTA-BONUS =
                   (WS-MONTHLY-SALES - WS-QUOTA) * 0.02
           ELSE
               MOVE ZEROS TO WS-QUOTA-BONUS
           END-IF
           COMPUTE WS-TOTAL-COMP =
               WS-COMMISSION + WS-QUOTA-BONUS
           DISPLAY 'REP:         ' WS-SALES-REP
           DISPLAY 'SALES:       ' WS-MONTHLY-SALES
           DISPLAY 'COMMISSION:  ' WS-COMMISSION
           DISPLAY 'QUOTA BONUS: ' WS-QUOTA-BONUS
           DISPLAY 'TOTAL COMP:  ' WS-TOTAL-COMP
           STOP RUN.
