       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-345.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 72.
       01  WS-YEARS             PIC 9(2)     VALUE 13.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 5987.69.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 61
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0016
               ELSE
                   COMPUTE WS-RATE = 0.0025
               END-IF
           ELSE
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0003
               ELSE
                   COMPUTE WS-RATE = 0.0001
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
