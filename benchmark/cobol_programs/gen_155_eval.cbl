       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-155.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 1265.37.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 3000
                   COMPUTE WS-RATE = 0.0044
               WHEN WS-AMOUNT <= 24000
                   COMPUTE WS-RATE = 0.0099
               WHEN WS-AMOUNT <= 28000
                   COMPUTE WS-RATE = 0.0063
               WHEN WS-AMOUNT <= 40000
                   COMPUTE WS-RATE = 0.0025
               WHEN WS-AMOUNT <= 47000
                   COMPUTE WS-RATE = 0.0029
               WHEN WS-AMOUNT <= 66000
                   COMPUTE WS-RATE = 0.0018
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0020
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
