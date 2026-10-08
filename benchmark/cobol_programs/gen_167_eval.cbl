       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-167.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8915.64.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 24000
                   COMPUTE WS-RATE = 0.0086
               WHEN WS-AMOUNT <= 31000
                   COMPUTE WS-RATE = 0.0011
               WHEN WS-AMOUNT <= 54000
                   COMPUTE WS-RATE = 0.0068
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0047
               WHEN WS-AMOUNT <= 86000
                   COMPUTE WS-RATE = 0.0009
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0068
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
