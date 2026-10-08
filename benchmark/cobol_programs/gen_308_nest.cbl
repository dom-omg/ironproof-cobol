       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-308.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 58.
       01  WS-YEARS             PIC 9(2)     VALUE 19.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 2827.86.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 69
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0019
               ELSE
                   COMPUTE WS-RATE = 0.0003
               END-IF
           ELSE
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0022
               ELSE
                   COMPUTE WS-RATE = 0.0005
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
