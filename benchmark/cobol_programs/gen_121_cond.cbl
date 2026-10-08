       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-COND-121.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT             PIC 9(5)V99  VALUE 6816.93.
       01  WS-THRESH            PIC 9(5)V99  VALUE 1558.40.
       01  WS-RATE1             PIC V9(4)    VALUE 0.0028.
       01  WS-RATE2             PIC V9(4)    VALUE 0.0071.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-INPUT >= WS-THRESH
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE1
           ELSE
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE2
           END-IF
           STOP RUN.
