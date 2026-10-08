       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-339.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 78.
       01  WS-YEARS             PIC 9(2)     VALUE 21.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 7249.27.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 55
               IF WS-YEARS >= 4
                   COMPUTE WS-RATE = 0.0005
               ELSE
                   COMPUTE WS-RATE = 0.0025
               END-IF
           ELSE
               IF WS-YEARS >= 4
                   COMPUTE WS-RATE = 0.0004
               ELSE
                   COMPUTE WS-RATE = 0.0019
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
