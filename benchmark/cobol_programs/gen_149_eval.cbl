       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-149.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8215.19.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0025
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0042
               WHEN WS-AMOUNT <= 84000
                   COMPUTE WS-RATE = 0.0078
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0061
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
