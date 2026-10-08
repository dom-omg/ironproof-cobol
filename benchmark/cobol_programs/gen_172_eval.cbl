       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-172.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6030.55.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 5000
                   COMPUTE WS-RATE = 0.0037
               WHEN WS-AMOUNT <= 25000
                   COMPUTE WS-RATE = 0.0046
               WHEN WS-AMOUNT <= 33000
                   COMPUTE WS-RATE = 0.0007
               WHEN WS-AMOUNT <= 61000
                   COMPUTE WS-RATE = 0.0084
               WHEN WS-AMOUNT <= 70000
                   COMPUTE WS-RATE = 0.0043
               WHEN WS-AMOUNT <= 83000
                   COMPUTE WS-RATE = 0.0035
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0016
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
