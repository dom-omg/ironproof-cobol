       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-158.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 7565.98.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 30000
                   COMPUTE WS-RATE = 0.0061
               WHEN WS-AMOUNT <= 31000
                   COMPUTE WS-RATE = 0.0025
               WHEN WS-AMOUNT <= 40000
                   COMPUTE WS-RATE = 0.0048
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0087
               WHEN WS-AMOUNT <= 69000
                   COMPUTE WS-RATE = 0.0074
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0057
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
