       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-182.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6731.98.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 9000
                   COMPUTE WS-RATE = 0.0051
               WHEN WS-AMOUNT <= 12000
                   COMPUTE WS-RATE = 0.0092
               WHEN WS-AMOUNT <= 40000
                   COMPUTE WS-RATE = 0.0093
               WHEN WS-AMOUNT <= 79000
                   COMPUTE WS-RATE = 0.0062
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0068
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
