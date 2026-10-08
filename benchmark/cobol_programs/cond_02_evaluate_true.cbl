       IDENTIFICATION DIVISION.
       PROGRAM-ID. EVALUATE-TRUE-DEMO.
      *---------------------------------------------------------------
      * EVALUATE TRUE with 5+ WHEN clauses - order status routing
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ORDER-ID         PIC X(10)    VALUE 'ORD-112233'.
       01  WS-ORDER-AMOUNT     PIC 9(7)V99  VALUE 3500.00.
       01  WS-CUSTOMER-TYPE    PIC X        VALUE 'P'.
       01  WS-DAYS-OUTSTANDING PIC 9(3)     VALUE 15.
       01  WS-PRIORITY-CODE    PIC X(10)    VALUE SPACES.
       01  WS-HANDLER-TEAM     PIC X(15)    VALUE SPACES.
       01  WS-SLA-HOURS        PIC 9(3)     VALUE ZEROS.
       01  WS-ESCALATION       PIC X        VALUE 'N'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-ORDER-AMOUNT > 10000
                   AND WS-CUSTOMER-TYPE = 'P'
                   MOVE 'CRITICAL' TO WS-PRIORITY-CODE
                   MOVE 'EXEC TEAM' TO WS-HANDLER-TEAM
                   MOVE 4 TO WS-SLA-HOURS
                   MOVE 'Y' TO WS-ESCALATION
               WHEN WS-ORDER-AMOUNT > 5000
                   MOVE 'HIGH' TO WS-PRIORITY-CODE
                   MOVE 'SENIOR AGENTS' TO WS-HANDLER-TEAM
                   MOVE 8 TO WS-SLA-HOURS
                   MOVE 'N' TO WS-ESCALATION
               WHEN WS-DAYS-OUTSTANDING > 30
                   MOVE 'URGENT' TO WS-PRIORITY-CODE
                   MOVE 'COLLECTIONS' TO WS-HANDLER-TEAM
                   MOVE 2 TO WS-SLA-HOURS
                   MOVE 'Y' TO WS-ESCALATION
               WHEN WS-CUSTOMER-TYPE = 'P'
                   MOVE 'MEDIUM' TO WS-PRIORITY-CODE
                   MOVE 'PREMIUM DESK' TO WS-HANDLER-TEAM
                   MOVE 12 TO WS-SLA-HOURS
                   MOVE 'N' TO WS-ESCALATION
               WHEN WS-ORDER-AMOUNT > 1000
                   MOVE 'STANDARD' TO WS-PRIORITY-CODE
                   MOVE 'GENERAL TEAM' TO WS-HANDLER-TEAM
                   MOVE 24 TO WS-SLA-HOURS
                   MOVE 'N' TO WS-ESCALATION
               WHEN WS-DAYS-OUTSTANDING > 7
                   MOVE 'FOLLOW-UP' TO WS-PRIORITY-CODE
                   MOVE 'SUPPORT TEAM' TO WS-HANDLER-TEAM
                   MOVE 48 TO WS-SLA-HOURS
                   MOVE 'N' TO WS-ESCALATION
               WHEN OTHER
                   MOVE 'LOW' TO WS-PRIORITY-CODE
                   MOVE 'AUTO-PROCESS' TO WS-HANDLER-TEAM
                   MOVE 72 TO WS-SLA-HOURS
                   MOVE 'N' TO WS-ESCALATION
           END-EVALUATE
           DISPLAY 'ORDER:      ' WS-ORDER-ID
           DISPLAY 'PRIORITY:   ' WS-PRIORITY-CODE
           DISPLAY 'HANDLER:    ' WS-HANDLER-TEAM
           DISPLAY 'SLA HOURS:  ' WS-SLA-HOURS
           DISPLAY 'ESCALATION: ' WS-ESCALATION
           STOP RUN.
