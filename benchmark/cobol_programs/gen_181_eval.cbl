       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-181.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6045.59.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 16000
                   COMPUTE WS-RATE = 0.0064
               WHEN WS-AMOUNT <= 18000
                   COMPUTE WS-RATE = 0.0004
               WHEN WS-AMOUNT <= 26000
                   COMPUTE WS-RATE = 0.0047
               WHEN WS-AMOUNT <= 31000
                   COMPUTE WS-RATE = 0.0071
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0074
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
