       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-319.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 94.
       01  WS-YEARS             PIC 9(2)     VALUE 18.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 5745.90.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 89
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0014
               ELSE
                   COMPUTE WS-RATE = 0.0006
               END-IF
           ELSE
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0020
               ELSE
                   COMPUTE WS-RATE = 0.0005
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
