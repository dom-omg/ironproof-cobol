       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-173.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 1294.55.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 24000
                   COMPUTE WS-RATE = 0.0064
               WHEN WS-AMOUNT <= 44000
                   COMPUTE WS-RATE = 0.0048
               WHEN WS-AMOUNT <= 50000
                   COMPUTE WS-RATE = 0.0067
               WHEN WS-AMOUNT <= 57000
                   COMPUTE WS-RATE = 0.0035
               WHEN WS-AMOUNT <= 64000
                   COMPUTE WS-RATE = 0.0011
               WHEN WS-AMOUNT <= 89000
                   COMPUTE WS-RATE = 0.0094
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0055
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
