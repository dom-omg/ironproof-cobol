       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-368.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 66.
       01  WS-YEARS             PIC 9(2)     VALUE 13.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 6103.58.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 55
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0004
               ELSE
                   COMPUTE WS-RATE = 0.0017
               END-IF
           ELSE
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0005
               ELSE
                   COMPUTE WS-RATE = 0.0021
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
