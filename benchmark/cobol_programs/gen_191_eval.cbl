       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-191.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 5365.73.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 13000
                   COMPUTE WS-RATE = 0.0007
               WHEN WS-AMOUNT <= 16000
                   COMPUTE WS-RATE = 0.0038
               WHEN WS-AMOUNT <= 19000
                   COMPUTE WS-RATE = 0.0050
               WHEN WS-AMOUNT <= 32000
                   COMPUTE WS-RATE = 0.0079
               WHEN WS-AMOUNT <= 35000
                   COMPUTE WS-RATE = 0.0054
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0032
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0021
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
