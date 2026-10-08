       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-COND-089.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT             PIC 9(5)V99  VALUE 5773.28.
       01  WS-THRESH            PIC 9(5)V99  VALUE 3116.79.
       01  WS-RATE1             PIC V9(4)    VALUE 0.0017.
       01  WS-RATE2             PIC V9(4)    VALUE 0.0094.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-INPUT < WS-THRESH
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE1
           ELSE
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE2
           END-IF
           STOP RUN.
