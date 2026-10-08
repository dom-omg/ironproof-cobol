       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-203.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 4332.78.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 41000
                   COMPUTE WS-RATE = 0.0023
               WHEN WS-AMOUNT <= 49000
                   COMPUTE WS-RATE = 0.0059
               WHEN WS-AMOUNT <= 62000
                   COMPUTE WS-RATE = 0.0069
               WHEN WS-AMOUNT <= 68000
                   COMPUTE WS-RATE = 0.0044
               WHEN WS-AMOUNT <= 85000
                   COMPUTE WS-RATE = 0.0070
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0046
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
