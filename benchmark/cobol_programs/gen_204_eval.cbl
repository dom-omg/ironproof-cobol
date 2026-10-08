       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-204.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8012.40.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 25000
                   COMPUTE WS-RATE = 0.0039
               WHEN WS-AMOUNT <= 29000
                   COMPUTE WS-RATE = 0.0099
               WHEN WS-AMOUNT <= 32000
                   COMPUTE WS-RATE = 0.0037
               WHEN WS-AMOUNT <= 36000
                   COMPUTE WS-RATE = 0.0091
               WHEN WS-AMOUNT <= 39000
                   COMPUTE WS-RATE = 0.0027
               WHEN WS-AMOUNT <= 72000
                   COMPUTE WS-RATE = 0.0089
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0091
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
