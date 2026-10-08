       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-364.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 98.
       01  WS-YEARS             PIC 9(2)     VALUE 24.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 3202.93.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 84
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0026
               ELSE
                   COMPUTE WS-RATE = 0.0008
               END-IF
           ELSE
               IF WS-YEARS >= 15
                   COMPUTE WS-RATE = 0.0005
               ELSE
                   COMPUTE WS-RATE = 0.0001
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
