       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-206.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 9209.89.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 11000
                   COMPUTE WS-RATE = 0.0096
               WHEN WS-AMOUNT <= 33000
                   COMPUTE WS-RATE = 0.0062
               WHEN WS-AMOUNT <= 45000
                   COMPUTE WS-RATE = 0.0028
               WHEN WS-AMOUNT <= 57000
                   COMPUTE WS-RATE = 0.0026
               WHEN WS-AMOUNT <= 84000
                   COMPUTE WS-RATE = 0.0069
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0035
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
