       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-151.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6698.99.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 57000
                   COMPUTE WS-RATE = 0.0021
               WHEN WS-AMOUNT <= 67000
                   COMPUTE WS-RATE = 0.0047
               WHEN WS-AMOUNT <= 68000
                   COMPUTE WS-RATE = 0.0048
               WHEN WS-AMOUNT <= 79000
                   COMPUTE WS-RATE = 0.0037
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0050
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
