       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-331.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 16.
       01  WS-YEARS             PIC 9(2)     VALUE 28.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 4946.20.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 67
               IF WS-YEARS >= 4
                   COMPUTE WS-RATE = 0.0021
               ELSE
                   COMPUTE WS-RATE = 0.0012
               END-IF
           ELSE
               IF WS-YEARS >= 4
                   COMPUTE WS-RATE = 0.0009
               ELSE
                   COMPUTE WS-RATE = 0.0003
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
