       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-193.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 7711.36.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 7000
                   COMPUTE WS-RATE = 0.0007
               WHEN WS-AMOUNT <= 28000
                   COMPUTE WS-RATE = 0.0037
               WHEN WS-AMOUNT <= 46000
                   COMPUTE WS-RATE = 0.0064
               WHEN WS-AMOUNT <= 75000
                   COMPUTE WS-RATE = 0.0077
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0084
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
