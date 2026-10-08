       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-332.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 47.
       01  WS-YEARS             PIC 9(2)     VALUE 21.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 2712.06.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 75
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0010
               ELSE
                   COMPUTE WS-RATE = 0.0024
               END-IF
           ELSE
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0023
               ELSE
                   COMPUTE WS-RATE = 0.0025
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
