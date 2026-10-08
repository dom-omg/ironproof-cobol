       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL-FULL.
      *---------------------------------------------------------------
      * Full payroll: gross, deductions (CPP, EI, tax), net pay
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-EMPLOYEE.
           05  WS-EMP-ID       PIC X(8)     VALUE 'EMP00789'.
           05  WS-EMP-NAME     PIC X(25)    VALUE 'GAGNON, PIERRE'.
           05  WS-EMP-PROVINCE PIC X(2)     VALUE 'QC'.
       01  WS-PAY-PERIOD.
           05  WS-HOURS-REG    PIC 9(3)V9   VALUE 80.0.
           05  WS-HOURS-OT     PIC 9(2)V9   VALUE 8.5.
           05  WS-HOURLY-RATE  PIC 9(3)V99  VALUE 35.00.
           05  WS-OT-MULT      PIC 9V99     VALUE 1.50.
       01  WS-GROSS.
           05  WS-REG-PAY      PIC 9(7)V99  VALUE ZEROS.
           05  WS-OT-PAY       PIC 9(6)V99  VALUE ZEROS.
           05  WS-GROSS-PAY    PIC 9(7)V99  VALUE ZEROS.
       01  WS-DEDUCTIONS.
           05  WS-CPP-RATE     PIC 9V9999   VALUE 0.0595.
           05  WS-CPP-MAX      PIC 9(5)V99  VALUE 3867.50.
           05  WS-CPP-EXEMPT   PIC 9(5)V99  VALUE 291.67.
           05  WS-CPP-AMT      PIC 9(5)V99  VALUE ZEROS.
           05  WS-EI-RATE      PIC 9V9999   VALUE 0.0166.
           05  WS-EI-MAX       PIC 9(5)V99  VALUE 1049.12.
           05  WS-EI-AMT       PIC 9(5)V99  VALUE ZEROS.
           05  WS-FED-TAX-AMT  PIC 9(5)V99  VALUE ZEROS.
           05  WS-PROV-TAX-AMT PIC 9(5)V99  VALUE ZEROS.
           05  WS-RRSP-AMT     PIC 9(5)V99  VALUE 200.00.
           05  WS-UNION-AMT    PIC 9(3)V99  VALUE 52.00.
           05  WS-HEALTH-AMT   PIC 9(3)V99  VALUE 45.00.
       01  WS-NET-PAY          PIC S9(7)V99 VALUE ZEROS.
       01  WS-TOTAL-DEDUCT     PIC 9(7)V99  VALUE ZEROS.
       01  WS-TAXABLE-INCOME   PIC 9(7)V99  VALUE ZEROS.
       01  WS-CPP-PENSIONABLE  PIC 9(7)V99  VALUE ZEROS.
       01  WS-ANNUAL-EQUIV     PIC 9(9)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           PERFORM CALC-GROSS
           PERFORM CALC-CPP
           PERFORM CALC-EI
           PERFORM CALC-TAXES
           PERFORM CALC-NET
           PERFORM DISPLAY-PAY-STUB
           STOP RUN.

       CALC-GROSS.
           COMPUTE WS-REG-PAY =
               WS-HOURS-REG * WS-HOURLY-RATE
           COMPUTE WS-OT-PAY =
               WS-HOURS-OT * WS-HOURLY-RATE * WS-OT-MULT
           COMPUTE WS-GROSS-PAY =
               WS-REG-PAY + WS-OT-PAY.

       CALC-CPP.
           COMPUTE WS-CPP-PENSIONABLE =
               WS-GROSS-PAY - WS-CPP-EXEMPT
           IF WS-CPP-PENSIONABLE < 0
               MOVE ZEROS TO WS-CPP-PENSIONABLE
           END-IF
           COMPUTE WS-CPP-AMT =
               WS-CPP-PENSIONABLE * WS-CPP-RATE
           IF WS-CPP-AMT > WS-CPP-MAX
               MOVE WS-CPP-MAX TO WS-CPP-AMT
           END-IF.

       CALC-EI.
           COMPUTE WS-EI-AMT =
               WS-GROSS-PAY * WS-EI-RATE
           IF WS-EI-AMT > WS-EI-MAX
               MOVE WS-EI-MAX TO WS-EI-AMT
           END-IF.

       CALC-TAXES.
           COMPUTE WS-TAXABLE-INCOME =
               WS-GROSS-PAY - WS-CPP-AMT
               - WS-EI-AMT - WS-RRSP-AMT
           COMPUTE WS-ANNUAL-EQUIV =
               WS-TAXABLE-INCOME * 26
           IF WS-ANNUAL-EQUIV <= 55867
               COMPUTE WS-FED-TAX-AMT =
                   WS-TAXABLE-INCOME * 0.1500
           ELSE IF WS-ANNUAL-EQUIV <= 111733
               COMPUTE WS-FED-TAX-AMT =
                   WS-TAXABLE-INCOME * 0.2050
           ELSE
               COMPUTE WS-FED-TAX-AMT =
                   WS-TAXABLE-INCOME * 0.2600
           END-IF
           IF WS-EMP-PROVINCE = 'QC'
               COMPUTE WS-PROV-TAX-AMT =
                   WS-TAXABLE-INCOME * 0.1500
           ELSE
               COMPUTE WS-PROV-TAX-AMT =
                   WS-TAXABLE-INCOME * 0.0505
           END-IF.

       CALC-NET.
           COMPUTE WS-TOTAL-DEDUCT =
               WS-CPP-AMT + WS-EI-AMT
               + WS-FED-TAX-AMT + WS-PROV-TAX-AMT
               + WS-RRSP-AMT + WS-UNION-AMT + WS-HEALTH-AMT
           COMPUTE WS-NET-PAY =
               WS-GROSS-PAY - WS-TOTAL-DEDUCT.

       DISPLAY-PAY-STUB.
           DISPLAY '======= PAY STUB ======='
           DISPLAY 'EMPLOYEE: ' WS-EMP-ID
               ' ' WS-EMP-NAME
           DISPLAY 'REGULAR:  ' WS-REG-PAY
           DISPLAY 'OVERTIME: ' WS-OT-PAY
           DISPLAY 'GROSS:    ' WS-GROSS-PAY
           DISPLAY '--- DEDUCTIONS ---'
           DISPLAY 'CPP:      ' WS-CPP-AMT
           DISPLAY 'EI:       ' WS-EI-AMT
           DISPLAY 'FED TAX:  ' WS-FED-TAX-AMT
           DISPLAY 'PROV TAX: ' WS-PROV-TAX-AMT
           DISPLAY 'RRSP:     ' WS-RRSP-AMT
           DISPLAY 'UNION:    ' WS-UNION-AMT
           DISPLAY 'HEALTH:   ' WS-HEALTH-AMT
           DISPLAY '--- TOTALS ---'
           DISPLAY 'DEDUCT:   ' WS-TOTAL-DEDUCT
           DISPLAY 'NET PAY:  ' WS-NET-PAY.
