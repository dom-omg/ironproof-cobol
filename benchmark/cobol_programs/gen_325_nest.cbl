       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-325.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 51.
       01  WS-YEARS             PIC 9(2)     VALUE 16.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 4559.88.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 73
               IF WS-YEARS >= 10
                   COMPUTE WS-RATE = 0.0016
               ELSE
                   COMPUTE WS-RATE = 0.0011
               END-IF
           ELSE
               IF WS-YEARS >= 10
                   COMPUTE WS-RATE = 0.0019
               ELSE
                   COMPUTE WS-RATE = 0.0001
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
