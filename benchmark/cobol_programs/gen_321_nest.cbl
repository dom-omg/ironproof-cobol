       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-321.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 21.
       01  WS-YEARS             PIC 9(2)     VALUE 10.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 4795.37.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 86
               IF WS-YEARS >= 7
                   COMPUTE WS-RATE = 0.0028
               ELSE
                   COMPUTE WS-RATE = 0.0017
               END-IF
           ELSE
               IF WS-YEARS >= 7
                   COMPUTE WS-RATE = 0.0029
               ELSE
                   COMPUTE WS-RATE = 0.0022
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
