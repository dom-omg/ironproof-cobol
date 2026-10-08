       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-346.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 75.
       01  WS-YEARS             PIC 9(2)     VALUE 2.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 226.33.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 63
               IF WS-YEARS >= 3
                   COMPUTE WS-RATE = 0.0030
               ELSE
                   COMPUTE WS-RATE = 0.0002
               END-IF
           ELSE
               IF WS-YEARS >= 3
                   COMPUTE WS-RATE = 0.0026
               ELSE
                   COMPUTE WS-RATE = 0.0013
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
