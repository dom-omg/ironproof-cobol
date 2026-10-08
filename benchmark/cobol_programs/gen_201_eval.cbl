       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-201.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6766.88.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 5000
                   COMPUTE WS-RATE = 0.0003
               WHEN WS-AMOUNT <= 15000
                   COMPUTE WS-RATE = 0.0057
               WHEN WS-AMOUNT <= 25000
                   COMPUTE WS-RATE = 0.0041
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0054
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0020
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
