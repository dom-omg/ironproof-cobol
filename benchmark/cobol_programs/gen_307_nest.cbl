       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-307.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 40.
       01  WS-YEARS             PIC 9(2)     VALUE 19.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 6368.78.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 75
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0004
               ELSE
                   COMPUTE WS-RATE = 0.0012
               END-IF
           ELSE
               IF WS-YEARS >= 12
                   COMPUTE WS-RATE = 0.0012
               ELSE
                   COMPUTE WS-RATE = 0.0028
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
