       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-208.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 85.70.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 43000
                   COMPUTE WS-RATE = 0.0013
               WHEN WS-AMOUNT <= 53000
                   COMPUTE WS-RATE = 0.0088
               WHEN WS-AMOUNT <= 61000
                   COMPUTE WS-RATE = 0.0099
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0018
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
