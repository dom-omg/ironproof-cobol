       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-361.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 22.
       01  WS-YEARS             PIC 9(2)     VALUE 7.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 8451.05.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 75
               IF WS-YEARS >= 4
                   COMPUTE WS-RATE = 0.0029
               ELSE
                   COMPUTE WS-RATE = 0.0015
               END-IF
           ELSE
               IF WS-YEARS >= 4
                   COMPUTE WS-RATE = 0.0028
               ELSE
                   COMPUTE WS-RATE = 0.0010
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
