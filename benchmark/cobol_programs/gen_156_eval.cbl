       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-156.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 2148.76.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0005
               WHEN WS-AMOUNT <= 68000
                   COMPUTE WS-RATE = 0.0085
               WHEN WS-AMOUNT <= 70000
                   COMPUTE WS-RATE = 0.0044
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0099
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
