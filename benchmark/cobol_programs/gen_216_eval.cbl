       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-216.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 3619.28.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 21000
                   COMPUTE WS-RATE = 0.0089
               WHEN WS-AMOUNT <= 40000
                   COMPUTE WS-RATE = 0.0016
               WHEN WS-AMOUNT <= 52000
                   COMPUTE WS-RATE = 0.0082
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0038
               WHEN WS-AMOUNT <= 88000
                   COMPUTE WS-RATE = 0.0048
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0079
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
