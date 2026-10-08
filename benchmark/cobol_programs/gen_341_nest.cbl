       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-341.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 10.
       01  WS-YEARS             PIC 9(2)     VALUE 7.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 9067.76.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 88
               IF WS-YEARS >= 14
                   COMPUTE WS-RATE = 0.0020
               ELSE
                   COMPUTE WS-RATE = 0.0010
               END-IF
           ELSE
               IF WS-YEARS >= 14
                   COMPUTE WS-RATE = 0.0025
               ELSE
                   COMPUTE WS-RATE = 0.0023
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
