       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-302.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 31.
       01  WS-YEARS             PIC 9(2)     VALUE 16.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 2859.70.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 60
               IF WS-YEARS >= 8
                   COMPUTE WS-RATE = 0.0018
               ELSE
                   COMPUTE WS-RATE = 0.0014
               END-IF
           ELSE
               IF WS-YEARS >= 8
                   COMPUTE WS-RATE = 0.0015
               ELSE
                   COMPUTE WS-RATE = 0.0008
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
