       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-179.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 2829.91.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 28000
                   COMPUTE WS-RATE = 0.0063
               WHEN WS-AMOUNT <= 37000
                   COMPUTE WS-RATE = 0.0026
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0016
               WHEN WS-AMOUNT <= 79000
                   COMPUTE WS-RATE = 0.0018
               WHEN WS-AMOUNT <= 89000
                   COMPUTE WS-RATE = 0.0010
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0058
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
