       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-315.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 36.
       01  WS-YEARS             PIC 9(2)     VALUE 5.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 7493.72.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 81
               IF WS-YEARS >= 11
                   COMPUTE WS-RATE = 0.0017
               ELSE
                   COMPUTE WS-RATE = 0.0004
               END-IF
           ELSE
               IF WS-YEARS >= 11
                   COMPUTE WS-RATE = 0.0019
               ELSE
                   COMPUTE WS-RATE = 0.0004
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
