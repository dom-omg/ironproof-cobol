       IDENTIFICATION DIVISION.
       PROGRAM-ID. VERB-SUBTRACT.
      *---------------------------------------------------------------
      * SUBTRACT with FROM and GIVING - payroll deductions
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-GROSS-PAY        PIC 9(7)V99  VALUE 4250.00.
       01  WS-FED-TAX          PIC 9(5)V99  VALUE 637.50.
       01  WS-PROV-TAX         PIC 9(5)V99  VALUE 510.00.
       01  WS-CPP              PIC 9(4)V99  VALUE 189.25.
       01  WS-EI               PIC 9(4)V99  VALUE 72.50.
       01  WS-RRSP             PIC 9(5)V99  VALUE 212.50.
       01  WS-UNION-DUES       PIC 9(3)V99  VALUE 42.50.
       01  WS-HEALTH-PREM      PIC 9(3)V99  VALUE 85.00.
       01  WS-AFTER-TAX        PIC S9(7)V99 VALUE ZEROS.
       01  WS-AFTER-STAT       PIC S9(7)V99 VALUE ZEROS.
       01  WS-AFTER-VOL        PIC S9(7)V99 VALUE ZEROS.
       01  WS-NET-PAY          PIC S9(7)V99 VALUE ZEROS.
       01  WS-TOTAL-DEDUCT     PIC 9(7)V99  VALUE ZEROS.
       01  WS-DEDUCT-PCT       PIC 9(2)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           SUBTRACT WS-FED-TAX FROM WS-GROSS-PAY
               GIVING WS-AFTER-TAX
           SUBTRACT WS-PROV-TAX FROM WS-AFTER-TAX
           SUBTRACT WS-CPP WS-EI FROM WS-AFTER-TAX
               GIVING WS-AFTER-STAT
           SUBTRACT WS-RRSP FROM WS-AFTER-STAT
               GIVING WS-AFTER-VOL
           SUBTRACT WS-UNION-DUES FROM WS-AFTER-VOL
           SUBTRACT WS-HEALTH-PREM FROM WS-AFTER-VOL
               GIVING WS-NET-PAY
           COMPUTE WS-TOTAL-DEDUCT =
               WS-FED-TAX + WS-PROV-TAX + WS-CPP
               + WS-EI + WS-RRSP + WS-UNION-DUES
               + WS-HEALTH-PREM
           IF WS-GROSS-PAY > 0
               COMPUTE WS-DEDUCT-PCT =
                   (WS-TOTAL-DEDUCT / 4250.00) * 100
           END-IF
           DISPLAY 'GROSS PAY:    ' WS-GROSS-PAY
           DISPLAY 'FED TAX:      ' WS-FED-TAX
           DISPLAY 'PROV TAX:     ' WS-PROV-TAX
           DISPLAY 'CPP:          ' WS-CPP
           DISPLAY 'EI:           ' WS-EI
           DISPLAY 'RRSP:         ' WS-RRSP
           DISPLAY 'UNION:        ' WS-UNION-DUES
           DISPLAY 'HEALTH:       ' WS-HEALTH-PREM
           DISPLAY 'NET PAY:      ' WS-NET-PAY
           DISPLAY 'TOTAL DEDUCT: ' WS-TOTAL-DEDUCT
           DISPLAY 'DEDUCT %:     ' WS-DEDUCT-PCT
           STOP RUN.
