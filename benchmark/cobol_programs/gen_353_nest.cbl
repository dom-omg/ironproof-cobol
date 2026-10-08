       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-353.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 63.
       01  WS-YEARS             PIC 9(2)     VALUE 30.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 5681.66.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 83
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0027
               ELSE
                   COMPUTE WS-RATE = 0.0024
               END-IF
           ELSE
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0009
               ELSE
                   COMPUTE WS-RATE = 0.0006
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
