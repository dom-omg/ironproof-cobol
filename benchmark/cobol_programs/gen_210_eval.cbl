       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-210.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 612.22.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 12000
                   COMPUTE WS-RATE = 0.0030
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0069
               WHEN WS-AMOUNT <= 84000
                   COMPUTE WS-RATE = 0.0095
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0093
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
