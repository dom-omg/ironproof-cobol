       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-366.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 42.
       01  WS-YEARS             PIC 9(2)     VALUE 0.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 6165.94.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 69
               IF WS-YEARS >= 4
                   COMPUTE WS-RATE = 0.0007
               ELSE
                   COMPUTE WS-RATE = 0.0017
               END-IF
           ELSE
               IF WS-YEARS >= 4
                   COMPUTE WS-RATE = 0.0008
               ELSE
                   COMPUTE WS-RATE = 0.0014
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
