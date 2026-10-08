       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-141.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6506.94.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 17000
                   COMPUTE WS-RATE = 0.0065
               WHEN WS-AMOUNT <= 30000
                   COMPUTE WS-RATE = 0.0072
               WHEN WS-AMOUNT <= 49000
                   COMPUTE WS-RATE = 0.0086
               WHEN WS-AMOUNT <= 69000
                   COMPUTE WS-RATE = 0.0046
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0010
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
