       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-219.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 2696.41.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 8000
                   COMPUTE WS-RATE = 0.0026
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0074
               WHEN WS-AMOUNT <= 71000
                   COMPUTE WS-RATE = 0.0069
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0020
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
