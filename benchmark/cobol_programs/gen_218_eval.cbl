       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-218.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 1280.72.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 11000
                   COMPUTE WS-RATE = 0.0068
               WHEN WS-AMOUNT <= 32000
                   COMPUTE WS-RATE = 0.0058
               WHEN WS-AMOUNT <= 77000
                   COMPUTE WS-RATE = 0.0068
               WHEN WS-AMOUNT <= 88000
                   COMPUTE WS-RATE = 0.0091
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0047
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
