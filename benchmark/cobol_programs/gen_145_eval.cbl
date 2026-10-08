       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-145.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 1235.22.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 14000
                   COMPUTE WS-RATE = 0.0019
               WHEN WS-AMOUNT <= 19000
                   COMPUTE WS-RATE = 0.0033
               WHEN WS-AMOUNT <= 31000
                   COMPUTE WS-RATE = 0.0026
               WHEN WS-AMOUNT <= 45000
                   COMPUTE WS-RATE = 0.0023
               WHEN WS-AMOUNT <= 83000
                   COMPUTE WS-RATE = 0.0078
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0020
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
