       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-359.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 4.
       01  WS-YEARS             PIC 9(2)     VALUE 17.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 6871.28.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 70
               IF WS-YEARS >= 6
                   COMPUTE WS-RATE = 0.0014
               ELSE
                   COMPUTE WS-RATE = 0.0030
               END-IF
           ELSE
               IF WS-YEARS >= 6
                   COMPUTE WS-RATE = 0.0024
               ELSE
                   COMPUTE WS-RATE = 0.0011
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
