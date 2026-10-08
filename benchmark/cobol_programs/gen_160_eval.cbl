       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-160.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 7362.65.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 16000
                   COMPUTE WS-RATE = 0.0011
               WHEN WS-AMOUNT <= 37000
                   COMPUTE WS-RATE = 0.0098
               WHEN WS-AMOUNT <= 67000
                   COMPUTE WS-RATE = 0.0021
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0035
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
