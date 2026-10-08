       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-178.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 4289.99.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 4000
                   COMPUTE WS-RATE = 0.0095
               WHEN WS-AMOUNT <= 15000
                   COMPUTE WS-RATE = 0.0024
               WHEN WS-AMOUNT <= 32000
                   COMPUTE WS-RATE = 0.0064
               WHEN WS-AMOUNT <= 36000
                   COMPUTE WS-RATE = 0.0067
               WHEN WS-AMOUNT <= 41000
                   COMPUTE WS-RATE = 0.0050
               WHEN WS-AMOUNT <= 84000
                   COMPUTE WS-RATE = 0.0072
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0016
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
