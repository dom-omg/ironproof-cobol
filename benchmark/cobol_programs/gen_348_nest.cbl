       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-348.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 68.
       01  WS-YEARS             PIC 9(2)     VALUE 17.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 2502.35.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 55
               IF WS-YEARS >= 7
                   COMPUTE WS-RATE = 0.0003
               ELSE
                   COMPUTE WS-RATE = 0.0017
               END-IF
           ELSE
               IF WS-YEARS >= 7
                   COMPUTE WS-RATE = 0.0030
               ELSE
                   COMPUTE WS-RATE = 0.0007
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
