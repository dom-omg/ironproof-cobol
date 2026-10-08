       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-189.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 3343.43.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 8000
                   COMPUTE WS-RATE = 0.0057
               WHEN WS-AMOUNT <= 21000
                   COMPUTE WS-RATE = 0.0054
               WHEN WS-AMOUNT <= 89000
                   COMPUTE WS-RATE = 0.0062
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0060
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
