       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-313.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 71.
       01  WS-YEARS             PIC 9(2)     VALUE 16.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 8110.52.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 81
               IF WS-YEARS >= 9
                   COMPUTE WS-RATE = 0.0023
               ELSE
                   COMPUTE WS-RATE = 0.0027
               END-IF
           ELSE
               IF WS-YEARS >= 9
                   COMPUTE WS-RATE = 0.0015
               ELSE
                   COMPUTE WS-RATE = 0.0016
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
