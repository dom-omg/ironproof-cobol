       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMPOUND-ARITH-TEST.
      *---------------------------------------------------------------
      * Compound chained arithmetic stress test
      * Tests cascading intermediate results through verb sequences
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-HOURS-REG     PIC 9(3)V99  VALUE ZEROS.
       01  WS-HOURS-OT      PIC 9(3)V99  VALUE ZEROS.
       01  WS-RATE           PIC 9(4)V99  VALUE ZEROS.
       01  WS-OT-MULT        PIC 9V99     VALUE 1.50.
       01  WS-REG-PAY        PIC 9(6)V99  VALUE ZEROS.
       01  WS-OT-PAY         PIC 9(6)V99  VALUE ZEROS.
       01  WS-GROSS          PIC 9(6)V99  VALUE ZEROS.
       01  WS-FED-TAX-RATE   PIC V9(4)    VALUE 0.22.
       01  WS-STATE-TAX-RATE PIC V9(4)    VALUE 0.05.
       01  WS-FICA-RATE      PIC V9(4)    VALUE 0.0765.
       01  WS-FED-TAX        PIC 9(5)V99  VALUE ZEROS.
       01  WS-STATE-TAX      PIC 9(5)V99  VALUE ZEROS.
       01  WS-FICA           PIC 9(5)V99  VALUE ZEROS.
       01  WS-TOTAL-DEDUCT   PIC 9(6)V99  VALUE ZEROS.
       01  WS-NET-PAY        PIC 9(6)V99  VALUE ZEROS.
       01  WS-BENEFIT-COST   PIC 9(4)V99  VALUE 185.50.
       01  WS-401K-PCT       PIC V9(4)    VALUE 0.06.
       01  WS-401K-AMT       PIC 9(5)V99  VALUE ZEROS.
       01  WS-TAKE-HOME      PIC 9(6)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MULTIPLY WS-HOURS-REG BY WS-RATE
               GIVING WS-REG-PAY
           COMPUTE WS-OT-PAY =
               WS-HOURS-OT * WS-RATE * WS-OT-MULT
           ADD WS-REG-PAY WS-OT-PAY GIVING WS-GROSS
           COMPUTE WS-FED-TAX = WS-GROSS * WS-FED-TAX-RATE
           COMPUTE WS-STATE-TAX = WS-GROSS * WS-STATE-TAX-RATE
           COMPUTE WS-FICA = WS-GROSS * WS-FICA-RATE
           ADD WS-FED-TAX WS-STATE-TAX WS-FICA
               GIVING WS-TOTAL-DEDUCT
           SUBTRACT WS-TOTAL-DEDUCT FROM WS-GROSS
               GIVING WS-NET-PAY
           COMPUTE WS-401K-AMT = WS-GROSS * WS-401K-PCT
           SUBTRACT WS-401K-AMT FROM WS-NET-PAY
           SUBTRACT WS-BENEFIT-COST FROM WS-NET-PAY
               GIVING WS-TAKE-HOME
           DISPLAY 'REG PAY:       ' WS-REG-PAY
           DISPLAY 'OT PAY:        ' WS-OT-PAY
           DISPLAY 'GROSS:         ' WS-GROSS
           DISPLAY 'FED TAX:       ' WS-FED-TAX
           DISPLAY 'STATE TAX:     ' WS-STATE-TAX
           DISPLAY 'FICA:          ' WS-FICA
           DISPLAY 'TOTAL DEDUCT:  ' WS-TOTAL-DEDUCT
           DISPLAY 'NET PAY:       ' WS-NET-PAY
           DISPLAY '401K:          ' WS-401K-AMT
           DISPLAY 'TAKE HOME:     ' WS-TAKE-HOME
           STOP RUN.
