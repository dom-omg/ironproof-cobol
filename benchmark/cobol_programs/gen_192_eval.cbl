       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-192.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8282.58.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 21000
                   COMPUTE WS-RATE = 0.0064
               WHEN WS-AMOUNT <= 25000
                   COMPUTE WS-RATE = 0.0040
               WHEN WS-AMOUNT <= 60000
                   COMPUTE WS-RATE = 0.0064
               WHEN WS-AMOUNT <= 64000
                   COMPUTE WS-RATE = 0.0003
               WHEN WS-AMOUNT <= 66000
                   COMPUTE WS-RATE = 0.0012
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0051
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
