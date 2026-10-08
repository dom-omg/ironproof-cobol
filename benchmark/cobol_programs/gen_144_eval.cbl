       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-144.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8356.24.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 11000
                   COMPUTE WS-RATE = 0.0043
               WHEN WS-AMOUNT <= 29000
                   COMPUTE WS-RATE = 0.0022
               WHEN WS-AMOUNT <= 40000
                   COMPUTE WS-RATE = 0.0010
               WHEN WS-AMOUNT <= 44000
                   COMPUTE WS-RATE = 0.0066
               WHEN WS-AMOUNT <= 51000
                   COMPUTE WS-RATE = 0.0082
               WHEN WS-AMOUNT <= 68000
                   COMPUTE WS-RATE = 0.0015
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0068
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
