       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-196.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 9140.46.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 36000
                   COMPUTE WS-RATE = 0.0079
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0016
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0017
               WHEN WS-AMOUNT <= 71000
                   COMPUTE WS-RATE = 0.0013
               WHEN WS-AMOUNT <= 80000
                   COMPUTE WS-RATE = 0.0051
               WHEN WS-AMOUNT <= 88000
                   COMPUTE WS-RATE = 0.0048
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0044
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
