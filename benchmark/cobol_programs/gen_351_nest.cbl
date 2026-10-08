       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-351.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 11.
       01  WS-YEARS             PIC 9(2)     VALUE 29.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 7119.14.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 79
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0020
               ELSE
                   COMPUTE WS-RATE = 0.0002
               END-IF
           ELSE
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0010
               ELSE
                   COMPUTE WS-RATE = 0.0022
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
