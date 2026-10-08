       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-324.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 80.
       01  WS-YEARS             PIC 9(2)     VALUE 13.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 6147.57.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 54
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0026
               ELSE
                   COMPUTE WS-RATE = 0.0029
               END-IF
           ELSE
               IF WS-YEARS >= 13
                   COMPUTE WS-RATE = 0.0025
               ELSE
                   COMPUTE WS-RATE = 0.0003
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
