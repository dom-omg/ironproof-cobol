       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-195.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 4729.09.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 7000
                   COMPUTE WS-RATE = 0.0072
               WHEN WS-AMOUNT <= 52000
                   COMPUTE WS-RATE = 0.0025
               WHEN WS-AMOUNT <= 73000
                   COMPUTE WS-RATE = 0.0047
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0071
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
