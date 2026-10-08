       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-358.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 1.
       01  WS-YEARS             PIC 9(2)     VALUE 7.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 754.60.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 73
               IF WS-YEARS >= 9
                   COMPUTE WS-RATE = 0.0030
               ELSE
                   COMPUTE WS-RATE = 0.0005
               END-IF
           ELSE
               IF WS-YEARS >= 9
                   COMPUTE WS-RATE = 0.0006
               ELSE
                   COMPUTE WS-RATE = 0.0030
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
