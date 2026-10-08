       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-183.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 9631.23.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 10000
                   COMPUTE WS-RATE = 0.0060
               WHEN WS-AMOUNT <= 17000
                   COMPUTE WS-RATE = 0.0088
               WHEN WS-AMOUNT <= 41000
                   COMPUTE WS-RATE = 0.0067
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0045
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0017
               WHEN WS-AMOUNT <= 83000
                   COMPUTE WS-RATE = 0.0071
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0082
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
