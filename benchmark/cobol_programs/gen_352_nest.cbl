       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-352.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 94.
       01  WS-YEARS             PIC 9(2)     VALUE 21.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 2878.15.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 50
               IF WS-YEARS >= 14
                   COMPUTE WS-RATE = 0.0005
               ELSE
                   COMPUTE WS-RATE = 0.0023
               END-IF
           ELSE
               IF WS-YEARS >= 14
                   COMPUTE WS-RATE = 0.0001
               ELSE
                   COMPUTE WS-RATE = 0.0006
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
