       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-362.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 99.
       01  WS-YEARS             PIC 9(2)     VALUE 27.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 5091.41.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 55
               IF WS-YEARS >= 11
                   COMPUTE WS-RATE = 0.0015
               ELSE
                   COMPUTE WS-RATE = 0.0001
               END-IF
           ELSE
               IF WS-YEARS >= 11
                   COMPUTE WS-RATE = 0.0012
               ELSE
                   COMPUTE WS-RATE = 0.0007
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
