       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-209.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 4677.82.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 53000
                   COMPUTE WS-RATE = 0.0084
               WHEN WS-AMOUNT <= 61000
                   COMPUTE WS-RATE = 0.0026
               WHEN WS-AMOUNT <= 62000
                   COMPUTE WS-RATE = 0.0097
               WHEN WS-AMOUNT <= 84000
                   COMPUTE WS-RATE = 0.0037
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0042
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
