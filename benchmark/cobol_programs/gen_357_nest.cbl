       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-357.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 98.
       01  WS-YEARS             PIC 9(2)     VALUE 3.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 9403.86.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 57
               IF WS-YEARS >= 6
                   COMPUTE WS-RATE = 0.0024
               ELSE
                   COMPUTE WS-RATE = 0.0017
               END-IF
           ELSE
               IF WS-YEARS >= 6
                   COMPUTE WS-RATE = 0.0001
               ELSE
                   COMPUTE WS-RATE = 0.0002
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
