       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-142.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 9395.51.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 3000
                   COMPUTE WS-RATE = 0.0010
               WHEN WS-AMOUNT <= 56000
                   COMPUTE WS-RATE = 0.0041
               WHEN WS-AMOUNT <= 59000
                   COMPUTE WS-RATE = 0.0074
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0055
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
