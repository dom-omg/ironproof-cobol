       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-207.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 3815.06.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 14000
                   COMPUTE WS-RATE = 0.0032
               WHEN WS-AMOUNT <= 18000
                   COMPUTE WS-RATE = 0.0007
               WHEN WS-AMOUNT <= 31000
                   COMPUTE WS-RATE = 0.0086
               WHEN WS-AMOUNT <= 76000
                   COMPUTE WS-RATE = 0.0068
               WHEN WS-AMOUNT <= 79000
                   COMPUTE WS-RATE = 0.0029
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0082
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
