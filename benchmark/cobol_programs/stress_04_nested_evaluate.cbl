       IDENTIFICATION DIVISION.
       PROGRAM-ID. NESTED-EVAL-TEST.
      *---------------------------------------------------------------
      * Complex nested EVALUATE with IF inside WHEN branches
      * Tests deep control flow with interleaved conditionals
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE          PIC 9(3)     VALUE ZEROS.
       01  WS-YEARS          PIC 9(2)     VALUE ZEROS.
       01  WS-GRADE          PIC X        VALUE SPACES.
       01  WS-BONUS-RATE     PIC V9(4)    VALUE ZEROS.
       01  WS-BASE-SALARY    PIC 9(6)V99  VALUE 75000.00.
       01  WS-BONUS          PIC 9(6)V99  VALUE ZEROS.
       01  WS-SENIORITY-ADJ  PIC V9(4)    VALUE ZEROS.
       01  WS-FINAL-BONUS    PIC 9(6)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-SCORE >= 95
                   MOVE 'A' TO WS-GRADE
                   COMPUTE WS-BONUS-RATE = 0.15
                   IF WS-YEARS >= 10
                       COMPUTE WS-SENIORITY-ADJ = 0.05
                   ELSE
                       IF WS-YEARS >= 5
                           COMPUTE WS-SENIORITY-ADJ = 0.025
                       ELSE
                           COMPUTE WS-SENIORITY-ADJ = 0.01
                       END-IF
                   END-IF
               WHEN WS-SCORE >= 85
                   MOVE 'B' TO WS-GRADE
                   COMPUTE WS-BONUS-RATE = 0.10
                   IF WS-YEARS >= 5
                       COMPUTE WS-SENIORITY-ADJ = 0.02
                   ELSE
                       COMPUTE WS-SENIORITY-ADJ = 0.005
                   END-IF
               WHEN WS-SCORE >= 70
                   MOVE 'C' TO WS-GRADE
                   COMPUTE WS-BONUS-RATE = 0.05
                   COMPUTE WS-SENIORITY-ADJ = 0.0
               WHEN OTHER
                   MOVE 'D' TO WS-GRADE
                   COMPUTE WS-BONUS-RATE = 0.0
                   COMPUTE WS-SENIORITY-ADJ = 0.0
           END-EVALUATE
           COMPUTE WS-BONUS = WS-BASE-SALARY *
               (WS-BONUS-RATE + WS-SENIORITY-ADJ)
           IF WS-BONUS > 15000
               MOVE 15000 TO WS-FINAL-BONUS
           ELSE
               MOVE WS-BONUS TO WS-FINAL-BONUS
           END-IF
           DISPLAY 'GRADE:        ' WS-GRADE
           DISPLAY 'BONUS RATE:   ' WS-BONUS-RATE
           DISPLAY 'SENIORITY:    ' WS-SENIORITY-ADJ
           DISPLAY 'BONUS:        ' WS-BONUS
           DISPLAY 'FINAL BONUS:  ' WS-FINAL-BONUS
           STOP RUN.
