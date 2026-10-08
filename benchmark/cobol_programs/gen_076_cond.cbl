       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-COND-076.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT             PIC 9(5)V99  VALUE 5189.80.
       01  WS-THRESH            PIC 9(5)V99  VALUE 7995.69.
       01  WS-RATE1             PIC V9(4)    VALUE 0.0003.
       01  WS-RATE2             PIC V9(4)    VALUE 0.0090.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-INPUT <= WS-THRESH
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE1
           ELSE
               COMPUTE WS-RESULT = WS-INPUT * WS-RATE2
           END-IF
           STOP RUN.
