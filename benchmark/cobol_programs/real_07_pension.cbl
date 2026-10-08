       IDENTIFICATION DIVISION.
       PROGRAM-ID. PENSION-BENEFIT.
      *---------------------------------------------------------------
      * Pension benefit calculation - defined benefit plan
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-MEMBER.
           05  WS-MEMBER-ID    PIC X(10)    VALUE 'PEN-012345'.
           05  WS-MEMBER-NAME  PIC X(25)    VALUE 'BOUCHARD, ROBERT'.
           05  WS-BIRTH-YEAR   PIC 9(4)     VALUE 1962.
           05  WS-HIRE-YEAR    PIC 9(4)     VALUE 1990.
           05  WS-RETIRE-YEAR  PIC 9(4)     VALUE 2027.
           05  WS-CURRENT-YEAR PIC 9(4)     VALUE 2024.
       01  WS-SALARY-HISTORY.
           05  WS-FINAL-5-AVG  PIC 9(9)V99  VALUE 92000.00.
           05  WS-BEST-5-AVG   PIC 9(9)V99  VALUE 95000.00.
           05  WS-CAREER-AVG   PIC 9(9)V99  VALUE 72000.00.
       01  WS-SERVICE.
           05  WS-TOTAL-YEARS  PIC 9(2)     VALUE ZEROS.
           05  WS-CREDITED-YRS PIC 9(2)V9   VALUE ZEROS.
           05  WS-RETIRE-AGE   PIC 9(2)     VALUE ZEROS.
           05  WS-CURRENT-AGE  PIC 9(2)     VALUE ZEROS.
       01  WS-PLAN-RULES.
           05  WS-ACCRUAL-RATE PIC 9V9999   VALUE 0.0200.
           05  WS-BRIDGE-RATE  PIC 9V9999   VALUE 0.0050.
           05  WS-EARLY-PENALTY PIC 9V9999  VALUE ZEROS.
           05  WS-NORMAL-AGE   PIC 9(2)     VALUE 65.
           05  WS-EARLY-AGE    PIC 9(2)     VALUE 55.
           05  WS-MAX-SERVICE  PIC 9(2)     VALUE 35.
           05  WS-PENALTY-RATE PIC 9V9999   VALUE 0.0050.
       01  WS-BENEFITS.
           05  WS-ANNUAL-BEN   PIC 9(8)V99  VALUE ZEROS.
           05  WS-MONTHLY-BEN  PIC 9(7)V99  VALUE ZEROS.
           05  WS-BRIDGE-BEN   PIC 9(6)V99  VALUE ZEROS.
           05  WS-TOTAL-MONTHLY PIC 9(7)V99 VALUE ZEROS.
           05  WS-COMMUTED-VAL PIC 9(10)V99 VALUE ZEROS.
           05  WS-REDUCTION    PIC 9V9999   VALUE ZEROS.
       01  WS-ELIGIBLE         PIC X        VALUE SPACES.
       01  WS-EARLY-RETIRE     PIC X        VALUE SPACES.
       01  WS-FACTOR-85        PIC 9(3)     VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           PERFORM CALC-SERVICE
           PERFORM CHECK-ELIGIBILITY
           PERFORM CALC-BENEFITS
           PERFORM CALC-COMMUTED-VALUE
           PERFORM DISPLAY-STATEMENT
           STOP RUN.

       CALC-SERVICE.
           COMPUTE WS-CURRENT-AGE =
               WS-CURRENT-YEAR - WS-BIRTH-YEAR
           COMPUTE WS-RETIRE-AGE =
               WS-RETIRE-YEAR - WS-BIRTH-YEAR
           COMPUTE WS-TOTAL-YEARS =
               WS-RETIRE-YEAR - WS-HIRE-YEAR
           IF WS-TOTAL-YEARS > WS-MAX-SERVICE
               MOVE WS-MAX-SERVICE TO WS-CREDITED-YRS
           ELSE
               MOVE WS-TOTAL-YEARS TO WS-CREDITED-YRS
           END-IF
           COMPUTE WS-FACTOR-85 =
               WS-RETIRE-AGE + WS-TOTAL-YEARS.

       CHECK-ELIGIBILITY.
           IF WS-RETIRE-AGE >= WS-NORMAL-AGE
               MOVE 'Y' TO WS-ELIGIBLE
               MOVE 'N' TO WS-EARLY-RETIRE
               MOVE 0.0000 TO WS-EARLY-PENALTY
           ELSE IF WS-RETIRE-AGE >= WS-EARLY-AGE
                   AND WS-TOTAL-YEARS >= 10
               MOVE 'Y' TO WS-ELIGIBLE
               MOVE 'Y' TO WS-EARLY-RETIRE
               IF WS-FACTOR-85 >= 85
                   MOVE 0.0000 TO WS-EARLY-PENALTY
               ELSE
                   COMPUTE WS-EARLY-PENALTY =
                       (WS-NORMAL-AGE - WS-RETIRE-AGE)
                       * WS-PENALTY-RATE
               END-IF
           ELSE
               MOVE 'N' TO WS-ELIGIBLE
           END-IF.

       CALC-BENEFITS.
           IF WS-ELIGIBLE = 'Y'
               COMPUTE WS-ANNUAL-BEN =
                   WS-BEST-5-AVG * WS-ACCRUAL-RATE
                   * WS-CREDITED-YRS
               COMPUTE WS-REDUCTION =
                   1 - WS-EARLY-PENALTY
               COMPUTE WS-ANNUAL-BEN =
                   WS-ANNUAL-BEN * WS-REDUCTION
               COMPUTE WS-MONTHLY-BEN =
                   WS-ANNUAL-BEN / 12
               IF WS-RETIRE-AGE < WS-NORMAL-AGE
                   COMPUTE WS-BRIDGE-BEN =
                       WS-BEST-5-AVG * WS-BRIDGE-RATE
                       * WS-CREDITED-YRS / 12
               ELSE
                   MOVE ZEROS TO WS-BRIDGE-BEN
               END-IF
               COMPUTE WS-TOTAL-MONTHLY =
                   WS-MONTHLY-BEN + WS-BRIDGE-BEN
           END-IF.

       CALC-COMMUTED-VALUE.
           IF WS-ELIGIBLE = 'Y'
               COMPUTE WS-COMMUTED-VAL =
                   WS-ANNUAL-BEN * 15
           END-IF.

       DISPLAY-STATEMENT.
           DISPLAY '=== PENSION STATEMENT ==='
           DISPLAY 'MEMBER:       ' WS-MEMBER-ID
           DISPLAY 'NAME:         ' WS-MEMBER-NAME
           DISPLAY 'CURRENT AGE:  ' WS-CURRENT-AGE
           DISPLAY 'RETIRE AGE:   ' WS-RETIRE-AGE
           DISPLAY 'SERVICE YRS:  ' WS-TOTAL-YEARS
           DISPLAY 'CREDITED YRS: ' WS-CREDITED-YRS
           DISPLAY 'FACTOR 85:    ' WS-FACTOR-85
           DISPLAY 'ELIGIBLE:     ' WS-ELIGIBLE
           IF WS-ELIGIBLE = 'Y'
               DISPLAY 'EARLY RETIRE: ' WS-EARLY-RETIRE
               DISPLAY 'PENALTY:      ' WS-EARLY-PENALTY
               DISPLAY 'ANNUAL BEN:   ' WS-ANNUAL-BEN
               DISPLAY 'MONTHLY BEN:  ' WS-MONTHLY-BEN
               DISPLAY 'BRIDGE BEN:   ' WS-BRIDGE-BEN
               DISPLAY 'TOTAL/MONTH:  ' WS-TOTAL-MONTHLY
               DISPLAY 'COMMUTED VAL: ' WS-COMMUTED-VAL
           ELSE
               DISPLAY 'NOT YET ELIGIBLE FOR BENEFITS'
           END-IF.
