       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-215.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 1937.59.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 2000
                   COMPUTE WS-RATE = 0.0034
               WHEN WS-AMOUNT <= 35000
                   COMPUTE WS-RATE = 0.0084
               WHEN WS-AMOUNT <= 39000
                   COMPUTE WS-RATE = 0.0047
               WHEN WS-AMOUNT <= 43000
                   COMPUTE WS-RATE = 0.0089
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0031
               WHEN WS-AMOUNT <= 75000
                   COMPUTE WS-RATE = 0.0008
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0086
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
