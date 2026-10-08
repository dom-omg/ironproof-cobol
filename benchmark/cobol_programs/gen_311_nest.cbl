       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-311.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 68.
       01  WS-YEARS             PIC 9(2)     VALUE 22.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 2839.71.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 60
               IF WS-YEARS >= 10
                   COMPUTE WS-RATE = 0.0010
               ELSE
                   COMPUTE WS-RATE = 0.0005
               END-IF
           ELSE
               IF WS-YEARS >= 10
                   COMPUTE WS-RATE = 0.0006
               ELSE
                   COMPUTE WS-RATE = 0.0011
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
