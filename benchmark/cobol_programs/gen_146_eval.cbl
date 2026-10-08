       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-146.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 1119.60.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0082
               WHEN WS-AMOUNT <= 60000
                   COMPUTE WS-RATE = 0.0080
               WHEN WS-AMOUNT <= 73000
                   COMPUTE WS-RATE = 0.0042
               WHEN WS-AMOUNT <= 75000
                   COMPUTE WS-RATE = 0.0081
               WHEN WS-AMOUNT <= 83000
                   COMPUTE WS-RATE = 0.0041
               WHEN WS-AMOUNT <= 88000
                   COMPUTE WS-RATE = 0.0020
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0057
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
