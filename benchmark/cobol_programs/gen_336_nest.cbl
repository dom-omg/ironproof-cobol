       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-336.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 93.
       01  WS-YEARS             PIC 9(2)     VALUE 25.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 1679.13.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 70
               IF WS-YEARS >= 8
                   COMPUTE WS-RATE = 0.0029
               ELSE
                   COMPUTE WS-RATE = 0.0010
               END-IF
           ELSE
               IF WS-YEARS >= 8
                   COMPUTE WS-RATE = 0.0005
               ELSE
                   COMPUTE WS-RATE = 0.0013
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
