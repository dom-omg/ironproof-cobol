       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-170.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 7841.80.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 44000
                   COMPUTE WS-RATE = 0.0083
               WHEN WS-AMOUNT <= 46000
                   COMPUTE WS-RATE = 0.0023
               WHEN WS-AMOUNT <= 70000
                   COMPUTE WS-RATE = 0.0088
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0060
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
