       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-164.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6935.14.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 20000
                   COMPUTE WS-RATE = 0.0071
               WHEN WS-AMOUNT <= 28000
                   COMPUTE WS-RATE = 0.0094
               WHEN WS-AMOUNT <= 33000
                   COMPUTE WS-RATE = 0.0078
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0068
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
