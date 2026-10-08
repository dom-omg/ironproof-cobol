       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-323.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 31.
       01  WS-YEARS             PIC 9(2)     VALUE 4.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 5278.31.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 75
               IF WS-YEARS >= 10
                   COMPUTE WS-RATE = 0.0005
               ELSE
                   COMPUTE WS-RATE = 0.0019
               END-IF
           ELSE
               IF WS-YEARS >= 10
                   COMPUTE WS-RATE = 0.0021
               ELSE
                   COMPUTE WS-RATE = 0.0009
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
