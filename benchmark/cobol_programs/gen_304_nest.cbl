       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-304.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 78.
       01  WS-YEARS             PIC 9(2)     VALUE 28.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 3233.57.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 87
               IF WS-YEARS >= 9
                   COMPUTE WS-RATE = 0.0013
               ELSE
                   COMPUTE WS-RATE = 0.0001
               END-IF
           ELSE
               IF WS-YEARS >= 9
                   COMPUTE WS-RATE = 0.0023
               ELSE
                   COMPUTE WS-RATE = 0.0007
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
