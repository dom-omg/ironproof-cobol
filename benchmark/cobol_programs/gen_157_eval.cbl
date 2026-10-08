       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-157.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 3892.56.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 20000
                   COMPUTE WS-RATE = 0.0093
               WHEN WS-AMOUNT <= 21000
                   COMPUTE WS-RATE = 0.0057
               WHEN WS-AMOUNT <= 22000
                   COMPUTE WS-RATE = 0.0006
               WHEN WS-AMOUNT <= 24000
                   COMPUTE WS-RATE = 0.0053
               WHEN WS-AMOUNT <= 80000
                   COMPUTE WS-RATE = 0.0047
               WHEN WS-AMOUNT <= 89000
                   COMPUTE WS-RATE = 0.0087
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0093
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
