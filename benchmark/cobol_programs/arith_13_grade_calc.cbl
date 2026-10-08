       IDENTIFICATION DIVISION.
       PROGRAM-ID. GRADE-CALCULATOR.
      *---------------------------------------------------------------
      * Weighted average grade calculation
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-STUDENT-ID       PIC X(8)     VALUE 'STU-1042'.
       01  WS-EXAM-SCORE       PIC 9(3)V99  VALUE 85.50.
       01  WS-MIDTERM-SCORE    PIC 9(3)V99  VALUE 72.00.
       01  WS-ASSIGN-SCORE     PIC 9(3)V99  VALUE 91.25.
       01  WS-PARTICIP-SCORE   PIC 9(3)V99  VALUE 88.00.
       01  WS-EXAM-WEIGHT      PIC 9V99     VALUE 0.40.
       01  WS-MIDTERM-WEIGHT   PIC 9V99     VALUE 0.25.
       01  WS-ASSIGN-WEIGHT    PIC 9V99     VALUE 0.25.
       01  WS-PARTICIP-WEIGHT  PIC 9V99     VALUE 0.10.
       01  WS-WEIGHTED-AVG     PIC 9(3)V99  VALUE ZEROS.
       01  WS-LETTER-GRADE     PIC X(2)     VALUE SPACES.
       01  WS-GPA-POINTS       PIC 9V99     VALUE ZEROS.
       01  WS-PASS-FLAG        PIC X        VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-WEIGHTED-AVG =
               WS-EXAM-SCORE * WS-EXAM-WEIGHT
               + WS-MIDTERM-SCORE * WS-MIDTERM-WEIGHT
               + WS-ASSIGN-SCORE * WS-ASSIGN-WEIGHT
               + WS-PARTICIP-SCORE * WS-PARTICIP-WEIGHT
           EVALUATE TRUE
               WHEN WS-WEIGHTED-AVG >= 90.00
                   MOVE 'A+' TO WS-LETTER-GRADE
                   MOVE 4.30 TO WS-GPA-POINTS
               WHEN WS-WEIGHTED-AVG >= 85.00
                   MOVE 'A ' TO WS-LETTER-GRADE
                   MOVE 4.00 TO WS-GPA-POINTS
               WHEN WS-WEIGHTED-AVG >= 80.00
                   MOVE 'A-' TO WS-LETTER-GRADE
                   MOVE 3.70 TO WS-GPA-POINTS
               WHEN WS-WEIGHTED-AVG >= 75.00
                   MOVE 'B+' TO WS-LETTER-GRADE
                   MOVE 3.30 TO WS-GPA-POINTS
               WHEN WS-WEIGHTED-AVG >= 70.00
                   MOVE 'B ' TO WS-LETTER-GRADE
                   MOVE 3.00 TO WS-GPA-POINTS
               WHEN WS-WEIGHTED-AVG >= 65.00
                   MOVE 'C+' TO WS-LETTER-GRADE
                   MOVE 2.30 TO WS-GPA-POINTS
               WHEN WS-WEIGHTED-AVG >= 60.00
                   MOVE 'C ' TO WS-LETTER-GRADE
                   MOVE 2.00 TO WS-GPA-POINTS
               WHEN OTHER
                   MOVE 'F ' TO WS-LETTER-GRADE
                   MOVE 0.00 TO WS-GPA-POINTS
           END-EVALUATE
           IF WS-WEIGHTED-AVG >= 60.00
               MOVE 'P' TO WS-PASS-FLAG
           ELSE
               MOVE 'F' TO WS-PASS-FLAG
           END-IF
           DISPLAY 'STUDENT: ' WS-STUDENT-ID
           DISPLAY 'AVERAGE: ' WS-WEIGHTED-AVG
           DISPLAY 'GRADE:   ' WS-LETTER-GRADE
           DISPLAY 'GPA:     ' WS-GPA-POINTS
           DISPLAY 'STATUS:  ' WS-PASS-FLAG
           STOP RUN.
