       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-163.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 87.10.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 5000
                   COMPUTE WS-RATE = 0.0098
               WHEN WS-AMOUNT <= 18000
                   COMPUTE WS-RATE = 0.0091
               WHEN WS-AMOUNT <= 37000
                   COMPUTE WS-RATE = 0.0061
               WHEN WS-AMOUNT <= 61000
                   COMPUTE WS-RATE = 0.0058
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0079
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
