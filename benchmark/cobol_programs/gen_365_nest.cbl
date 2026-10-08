       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-365.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 52.
       01  WS-YEARS             PIC 9(2)     VALUE 0.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 3818.69.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 72
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0027
               ELSE
                   COMPUTE WS-RATE = 0.0023
               END-IF
           ELSE
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0029
               ELSE
                   COMPUTE WS-RATE = 0.0001
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
