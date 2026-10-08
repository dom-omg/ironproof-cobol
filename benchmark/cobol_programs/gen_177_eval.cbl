       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-177.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8675.46.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 5000
                   COMPUTE WS-RATE = 0.0048
               WHEN WS-AMOUNT <= 20000
                   COMPUTE WS-RATE = 0.0048
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0057
               WHEN WS-AMOUNT <= 73000
                   COMPUTE WS-RATE = 0.0098
               WHEN WS-AMOUNT <= 78000
                   COMPUTE WS-RATE = 0.0010
               WHEN WS-AMOUNT <= 87000
                   COMPUTE WS-RATE = 0.0074
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0018
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
