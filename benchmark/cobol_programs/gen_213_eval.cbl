       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-213.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 1422.51.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 23000
                   COMPUTE WS-RATE = 0.0079
               WHEN WS-AMOUNT <= 25000
                   COMPUTE WS-RATE = 0.0082
               WHEN WS-AMOUNT <= 38000
                   COMPUTE WS-RATE = 0.0052
               WHEN WS-AMOUNT <= 73000
                   COMPUTE WS-RATE = 0.0055
               WHEN WS-AMOUNT <= 87000
                   COMPUTE WS-RATE = 0.0066
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0042
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
