       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-150.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 2828.05.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 14000
                   COMPUTE WS-RATE = 0.0092
               WHEN WS-AMOUNT <= 44000
                   COMPUTE WS-RATE = 0.0011
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0065
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0083
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
