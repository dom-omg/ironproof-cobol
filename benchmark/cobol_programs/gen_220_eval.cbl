       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-220.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 7485.72.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 12000
                   COMPUTE WS-RATE = 0.0066
               WHEN WS-AMOUNT <= 15000
                   COMPUTE WS-RATE = 0.0058
               WHEN WS-AMOUNT <= 27000
                   COMPUTE WS-RATE = 0.0008
               WHEN WS-AMOUNT <= 63000
                   COMPUTE WS-RATE = 0.0059
               WHEN WS-AMOUNT <= 75000
                   COMPUTE WS-RATE = 0.0017
               WHEN WS-AMOUNT <= 88000
                   COMPUTE WS-RATE = 0.0066
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0054
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
