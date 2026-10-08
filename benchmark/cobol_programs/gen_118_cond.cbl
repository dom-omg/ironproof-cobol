       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-COND-118.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT             PIC 9(5)V99  VALUE 9788.67.
       01  WS-THRESH            PIC 9(5)V99  VALUE 4832.58.
       01  WS-RATE1             PIC V9(4)    VALUE 0.0033.
       01  WS-RATE2             PIC V9(4)    VALUE 0.0089.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-INPUT > WS-THRESH
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE1
           ELSE
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE2
           END-IF
           STOP RUN.
