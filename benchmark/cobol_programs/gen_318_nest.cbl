       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-318.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 44.
       01  WS-YEARS             PIC 9(2)     VALUE 27.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 1426.56.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 57
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0026
               ELSE
                   COMPUTE WS-RATE = 0.0008
               END-IF
           ELSE
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0007
               ELSE
                   COMPUTE WS-RATE = 0.0026
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
