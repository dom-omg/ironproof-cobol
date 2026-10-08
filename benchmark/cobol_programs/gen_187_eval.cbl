       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-187.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 3454.98.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 4000
                   COMPUTE WS-RATE = 0.0083
               WHEN WS-AMOUNT <= 6000
                   COMPUTE WS-RATE = 0.0099
               WHEN WS-AMOUNT <= 11000
                   COMPUTE WS-RATE = 0.0074
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0034
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
