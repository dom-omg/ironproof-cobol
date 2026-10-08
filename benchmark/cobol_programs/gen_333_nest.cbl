       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-333.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 29.
       01  WS-YEARS             PIC 9(2)     VALUE 13.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 1495.90.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 56
               IF WS-YEARS >= 3
                   COMPUTE WS-RATE = 0.0007
               ELSE
                   COMPUTE WS-RATE = 0.0016
               END-IF
           ELSE
               IF WS-YEARS >= 3
                   COMPUTE WS-RATE = 0.0003
               ELSE
                   COMPUTE WS-RATE = 0.0005
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
