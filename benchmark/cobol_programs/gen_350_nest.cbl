       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-350.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 82.
       01  WS-YEARS             PIC 9(2)     VALUE 2.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 5082.89.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 77
               IF WS-YEARS >= 14
                   COMPUTE WS-RATE = 0.0028
               ELSE
                   COMPUTE WS-RATE = 0.0008
               END-IF
           ELSE
               IF WS-YEARS >= 14
                   COMPUTE WS-RATE = 0.0002
               ELSE
                   COMPUTE WS-RATE = 0.0008
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
