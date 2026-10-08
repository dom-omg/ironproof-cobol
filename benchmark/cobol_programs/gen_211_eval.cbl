       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-211.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 4663.58.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 5000
                   COMPUTE WS-RATE = 0.0005
               WHEN WS-AMOUNT <= 23000
                   COMPUTE WS-RATE = 0.0002
               WHEN WS-AMOUNT <= 24000
                   COMPUTE WS-RATE = 0.0039
               WHEN WS-AMOUNT <= 38000
                   COMPUTE WS-RATE = 0.0073
               WHEN WS-AMOUNT <= 51000
                   COMPUTE WS-RATE = 0.0078
               WHEN WS-AMOUNT <= 64000
                   COMPUTE WS-RATE = 0.0014
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0043
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
