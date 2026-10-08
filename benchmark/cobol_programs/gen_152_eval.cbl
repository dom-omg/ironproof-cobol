       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-152.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6334.36.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 7000
                   COMPUTE WS-RATE = 0.0043
               WHEN WS-AMOUNT <= 77000
                   COMPUTE WS-RATE = 0.0009
               WHEN WS-AMOUNT <= 81000
                   COMPUTE WS-RATE = 0.0043
               WHEN WS-AMOUNT <= 83000
                   COMPUTE WS-RATE = 0.0013
               WHEN WS-AMOUNT <= 87000
                   COMPUTE WS-RATE = 0.0072
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0087
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
