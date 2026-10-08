       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-199.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 437.76.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 3000
                   COMPUTE WS-RATE = 0.0087
               WHEN WS-AMOUNT <= 39000
                   COMPUTE WS-RATE = 0.0015
               WHEN WS-AMOUNT <= 43000
                   COMPUTE WS-RATE = 0.0054
               WHEN WS-AMOUNT <= 48000
                   COMPUTE WS-RATE = 0.0075
               WHEN WS-AMOUNT <= 61000
                   COMPUTE WS-RATE = 0.0040
               WHEN WS-AMOUNT <= 73000
                   COMPUTE WS-RATE = 0.0093
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0089
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
