       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-212.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 3051.01.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 15000
                   COMPUTE WS-RATE = 0.0043
               WHEN WS-AMOUNT <= 18000
                   COMPUTE WS-RATE = 0.0021
               WHEN WS-AMOUNT <= 25000
                   COMPUTE WS-RATE = 0.0094
               WHEN WS-AMOUNT <= 35000
                   COMPUTE WS-RATE = 0.0059
               WHEN WS-AMOUNT <= 60000
                   COMPUTE WS-RATE = 0.0083
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0033
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0092
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
