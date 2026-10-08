       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL-GROSS.
      *---------------------------------------------------------------
      * Gross pay calculation with overtime (1.5x over 40 hours)
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-EMPLOYEE-ID      PIC X(8)     VALUE 'EMP00142'.
       01  WS-HOURLY-RATE      PIC 9(3)V99  VALUE 28.50.
       01  WS-HOURS-WORKED     PIC 9(3)V9   VALUE 47.5.
       01  WS-REGULAR-LIMIT    PIC 9(3)     VALUE 40.
       01  WS-OT-MULTIPLIER    PIC 9V99     VALUE 1.50.
       01  WS-REGULAR-PAY      PIC 9(6)V99  VALUE ZEROS.
       01  WS-OVERTIME-PAY     PIC 9(6)V99  VALUE ZEROS.
       01  WS-GROSS-PAY        PIC 9(6)V99  VALUE ZEROS.
       01  WS-OT-HOURS         PIC 9(3)V9   VALUE ZEROS.
       01  WS-OT-RATE          PIC 9(3)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-HOURS-WORKED > WS-REGULAR-LIMIT
               COMPUTE WS-REGULAR-PAY =
                   WS-REGULAR-LIMIT * WS-HOURLY-RATE
               COMPUTE WS-OT-HOURS =
                   WS-HOURS-WORKED - WS-REGULAR-LIMIT
               COMPUTE WS-OT-RATE =
                   WS-HOURLY-RATE * WS-OT-MULTIPLIER
               COMPUTE WS-OVERTIME-PAY =
                   WS-OT-HOURS * WS-OT-RATE
           ELSE
               COMPUTE WS-REGULAR-PAY =
                   WS-HOURS-WORKED * WS-HOURLY-RATE
               MOVE ZEROS TO WS-OVERTIME-PAY
           END-IF
           COMPUTE WS-GROSS-PAY =
               WS-REGULAR-PAY + WS-OVERTIME-PAY
           DISPLAY 'EMPLOYEE:     ' WS-EMPLOYEE-ID
           DISPLAY 'REGULAR PAY:  ' WS-REGULAR-PAY
           DISPLAY 'OVERTIME PAY: ' WS-OVERTIME-PAY
           DISPLAY 'GROSS PAY:    ' WS-GROSS-PAY
           STOP RUN.
