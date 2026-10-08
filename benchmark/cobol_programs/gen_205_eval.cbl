       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-205.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 4759.05.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 16000
                   COMPUTE WS-RATE = 0.0087
               WHEN WS-AMOUNT <= 36000
                   COMPUTE WS-RATE = 0.0070
               WHEN WS-AMOUNT <= 37000
                   COMPUTE WS-RATE = 0.0049
               WHEN WS-AMOUNT <= 45000
                   COMPUTE WS-RATE = 0.0051
               WHEN WS-AMOUNT <= 72000
                   COMPUTE WS-RATE = 0.0045
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0099
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0019
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
