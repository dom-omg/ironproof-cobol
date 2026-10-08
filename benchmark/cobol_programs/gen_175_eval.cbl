       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-175.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 1230.85.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 6000
                   COMPUTE WS-RATE = 0.0094
               WHEN WS-AMOUNT <= 22000
                   COMPUTE WS-RATE = 0.0046
               WHEN WS-AMOUNT <= 45000
                   COMPUTE WS-RATE = 0.0079
               WHEN WS-AMOUNT <= 57000
                   COMPUTE WS-RATE = 0.0056
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0036
               WHEN WS-AMOUNT <= 89000
                   COMPUTE WS-RATE = 0.0082
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0008
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
