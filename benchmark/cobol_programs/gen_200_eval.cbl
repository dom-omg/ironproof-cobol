       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-200.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6230.18.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 7000
                   COMPUTE WS-RATE = 0.0075
               WHEN WS-AMOUNT <= 30000
                   COMPUTE WS-RATE = 0.0062
               WHEN WS-AMOUNT <= 34000
                   COMPUTE WS-RATE = 0.0022
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0068
               WHEN WS-AMOUNT <= 75000
                   COMPUTE WS-RATE = 0.0081
               WHEN WS-AMOUNT <= 84000
                   COMPUTE WS-RATE = 0.0093
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0080
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
