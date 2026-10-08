       IDENTIFICATION DIVISION.
       PROGRAM-ID. DIV-INTO-TEST.
      *---------------------------------------------------------------
      * DIVIDE INTO vs DIVIDE BY semantics stress test
      * DIVIDE A INTO B means B = B / A (NOT A / B)
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-DIVISOR       PIC 9(3)     VALUE 4.
       01  WS-AMOUNT        PIC 9(5)V99  VALUE 100.00.
       01  WS-RESULT-INTO   PIC 9(5)V99  VALUE ZEROS.
       01  WS-RESULT-BY     PIC 9(5)V99  VALUE ZEROS.
       01  WS-QUOTIENT      PIC 9(5)V99  VALUE ZEROS.
       01  WS-REMAINDER     PIC 9(5)V99  VALUE ZEROS.
       01  WS-TOTAL-ITEMS   PIC 9(4)     VALUE 360.
       01  WS-NUM-GROUPS    PIC 9(3)     VALUE 12.
       01  WS-PER-GROUP     PIC 9(4)V99  VALUE ZEROS.
       01  WS-SALARY        PIC 9(6)V99  VALUE 78000.00.
       01  WS-MONTHS        PIC 9(2)     VALUE 12.
       01  WS-MONTHLY-PAY   PIC 9(6)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE WS-AMOUNT TO WS-RESULT-INTO
           DIVIDE WS-DIVISOR INTO WS-RESULT-INTO
           DIVIDE WS-AMOUNT BY WS-DIVISOR
               GIVING WS-RESULT-BY
           DIVIDE WS-TOTAL-ITEMS BY WS-NUM-GROUPS
               GIVING WS-QUOTIENT REMAINDER WS-REMAINDER
           DIVIDE WS-MONTHS INTO WS-SALARY
               GIVING WS-MONTHLY-PAY
           DIVIDE WS-NUM-GROUPS INTO WS-PER-GROUP
           DISPLAY 'INTO RESULT:   ' WS-RESULT-INTO
           DISPLAY 'BY RESULT:     ' WS-RESULT-BY
           DISPLAY 'QUOTIENT:      ' WS-QUOTIENT
           DISPLAY 'REMAINDER:     ' WS-REMAINDER
           DISPLAY 'MONTHLY PAY:   ' WS-MONTHLY-PAY
           DISPLAY 'PER GROUP:     ' WS-PER-GROUP
           STOP RUN.
