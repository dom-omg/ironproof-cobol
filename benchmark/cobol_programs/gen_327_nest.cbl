       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-327.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 8.
       01  WS-YEARS             PIC 9(2)     VALUE 25.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 8757.50.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 63
               IF WS-YEARS >= 9
                   COMPUTE WS-RATE = 0.0027
               ELSE
                   COMPUTE WS-RATE = 0.0007
               END-IF
           ELSE
               IF WS-YEARS >= 9
                   COMPUTE WS-RATE = 0.0016
               ELSE
                   COMPUTE WS-RATE = 0.0009
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
