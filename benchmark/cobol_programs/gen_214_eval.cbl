       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-214.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6285.30.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 18000
                   COMPUTE WS-RATE = 0.0042
               WHEN WS-AMOUNT <= 24000
                   COMPUTE WS-RATE = 0.0032
               WHEN WS-AMOUNT <= 62000
                   COMPUTE WS-RATE = 0.0001
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0034
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
