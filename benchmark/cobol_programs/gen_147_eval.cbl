       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-147.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6042.36.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 8000
                   COMPUTE WS-RATE = 0.0065
               WHEN WS-AMOUNT <= 36000
                   COMPUTE WS-RATE = 0.0010
               WHEN WS-AMOUNT <= 39000
                   COMPUTE WS-RATE = 0.0040
               WHEN WS-AMOUNT <= 46000
                   COMPUTE WS-RATE = 0.0060
               WHEN WS-AMOUNT <= 76000
                   COMPUTE WS-RATE = 0.0058
               WHEN WS-AMOUNT <= 81000
                   COMPUTE WS-RATE = 0.0005
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0008
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
