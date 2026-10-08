       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-342.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 3.
       01  WS-YEARS             PIC 9(2)     VALUE 27.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 4943.26.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 83
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0017
               ELSE
                   COMPUTE WS-RATE = 0.0007
               END-IF
           ELSE
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0024
               ELSE
                   COMPUTE WS-RATE = 0.0013
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
