       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-356.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 58.
       01  WS-YEARS             PIC 9(2)     VALUE 16.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 5901.07.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 81
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0006
               ELSE
                   COMPUTE WS-RATE = 0.0012
               END-IF
           ELSE
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0006
               ELSE
                   COMPUTE WS-RATE = 0.0009
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
