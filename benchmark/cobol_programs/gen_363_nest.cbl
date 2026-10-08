       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-363.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 37.
       01  WS-YEARS             PIC 9(2)     VALUE 18.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 4980.94.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 89
               IF WS-YEARS >= 6
                   COMPUTE WS-RATE = 0.0015
               ELSE
                   COMPUTE WS-RATE = 0.0012
               END-IF
           ELSE
               IF WS-YEARS >= 6
                   COMPUTE WS-RATE = 0.0019
               ELSE
                   COMPUTE WS-RATE = 0.0016
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
