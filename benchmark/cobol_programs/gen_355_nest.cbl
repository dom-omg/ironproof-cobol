       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-NEST-355.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SCORE             PIC 9(3)     VALUE 54.
       01  WS-YEARS             PIC 9(2)     VALUE 8.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-BONUS             PIC 9(6)V99  VALUE ZEROS.
       01  WS-BASE              PIC 9(6)V99  VALUE 8583.08.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-SCORE >= 66
               IF WS-YEARS >= 14
                   COMPUTE WS-RATE = 0.0019
               ELSE
                   COMPUTE WS-RATE = 0.0021
               END-IF
           ELSE
               IF WS-YEARS >= 14
                   COMPUTE WS-RATE = 0.0003
               ELSE
                   COMPUTE WS-RATE = 0.0016
               END-IF
           END-IF
           COMPUTE WS-BONUS = WS-BASE * WS-RATE
           STOP RUN.
