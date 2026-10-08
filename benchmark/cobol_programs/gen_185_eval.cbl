       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-185.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 2051.80.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 11000
                   COMPUTE WS-RATE = 0.0033
               WHEN WS-AMOUNT <= 37000
                   COMPUTE WS-RATE = 0.0026
               WHEN WS-AMOUNT <= 45000
                   COMPUTE WS-RATE = 0.0082
               WHEN WS-AMOUNT <= 67000
                   COMPUTE WS-RATE = 0.0071
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0036
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
