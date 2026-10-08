       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-161.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8225.47.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 12000
                   COMPUTE WS-RATE = 0.0045
               WHEN WS-AMOUNT <= 29000
                   COMPUTE WS-RATE = 0.0004
               WHEN WS-AMOUNT <= 56000
                   COMPUTE WS-RATE = 0.0054
               WHEN WS-AMOUNT <= 58000
                   COMPUTE WS-RATE = 0.0007
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0051
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
