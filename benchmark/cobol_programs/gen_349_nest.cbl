       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-349.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 19.
       01  WS-YEARS             PIC 9(2)     VALUE 17.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 5354.50.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 87
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0025
               ELSE
                   COMPUTE WS-RATE = 0.0027
               END-IF
           ELSE
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0021
               ELSE
                   COMPUTE WS-RATE = 0.0022
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
