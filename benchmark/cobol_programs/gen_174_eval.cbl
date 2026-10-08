       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-174.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 7306.77.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 14000
                   COMPUTE WS-RATE = 0.0011
               WHEN WS-AMOUNT <= 38000
                   COMPUTE WS-RATE = 0.0042
               WHEN WS-AMOUNT <= 42000
                   COMPUTE WS-RATE = 0.0085
               WHEN WS-AMOUNT <= 70000
                   COMPUTE WS-RATE = 0.0038
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0040
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
