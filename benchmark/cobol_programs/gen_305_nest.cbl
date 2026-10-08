       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-305.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 26.
       01  WS-YEARS             PIC 9(2)     VALUE 8.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 1026.73.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 56
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0028
               ELSE
                   COMPUTE WS-RATE = 0.0018
               END-IF
           ELSE
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0006
               ELSE
                   COMPUTE WS-RATE = 0.0012
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
