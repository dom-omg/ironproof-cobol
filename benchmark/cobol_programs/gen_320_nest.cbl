       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-320.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 100.
       01  WS-YEARS             PIC 9(2)     VALUE 6.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 3391.07.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 86
               IF WS-YEARS >= 8
                   COMPUTE WS-RATE = 0.0018
               ELSE
                   COMPUTE WS-RATE = 0.0009
               END-IF
           ELSE
               IF WS-YEARS >= 8
                   COMPUTE WS-RATE = 0.0020
               ELSE
                   COMPUTE WS-RATE = 0.0018
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
