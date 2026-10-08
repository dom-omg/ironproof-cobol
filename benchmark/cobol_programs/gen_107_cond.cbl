       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-COND-107.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT             PIC 9(5)V99  VALUE 829.42.
       01  WS-THRESH            PIC 9(5)V99  VALUE 3991.16.
       01  WS-RATE1             PIC V9(4)    VALUE 0.0037.
       01  WS-RATE2             PIC V9(4)    VALUE 0.0064.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-INPUT <= WS-THRESH
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE1
           ELSE
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE2
           END-IF
           STOP RUN.
