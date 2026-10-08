       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-168.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 267.45.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 6000
                   COMPUTE WS-RATE = 0.0082
               WHEN WS-AMOUNT <= 50000
                   COMPUTE WS-RATE = 0.0050
               WHEN WS-AMOUNT <= 61000
                   COMPUTE WS-RATE = 0.0048
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0033
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
