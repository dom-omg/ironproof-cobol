       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-306.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 41.
       01  WS-YEARS             PIC 9(2)     VALUE 6.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 7497.14.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 66
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0028
               ELSE
                   COMPUTE WS-RATE = 0.0016
               END-IF
           ELSE
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0017
               ELSE
                   COMPUTE WS-RATE = 0.0021
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
