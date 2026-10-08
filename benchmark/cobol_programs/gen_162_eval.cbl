       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-162.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 5494.18.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 11000
                   COMPUTE WS-RATE = 0.0004
               WHEN WS-AMOUNT <= 29000
                   COMPUTE WS-RATE = 0.0041
               WHEN WS-AMOUNT <= 48000
                   COMPUTE WS-RATE = 0.0013
               WHEN WS-AMOUNT <= 50000
                   COMPUTE WS-RATE = 0.0092
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0084
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
