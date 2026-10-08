       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-171.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 5171.39.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 5000
                   COMPUTE WS-RATE = 0.0038
               WHEN WS-AMOUNT <= 9000
                   COMPUTE WS-RATE = 0.0026
               WHEN WS-AMOUNT <= 18000
                   COMPUTE WS-RATE = 0.0006
               WHEN WS-AMOUNT <= 59000
                   COMPUTE WS-RATE = 0.0026
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0006
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
