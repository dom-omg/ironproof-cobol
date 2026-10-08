       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-217.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8807.85.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 20000
                   COMPUTE WS-RATE = 0.0048
               WHEN WS-AMOUNT <= 59000
                   COMPUTE WS-RATE = 0.0054
               WHEN WS-AMOUNT <= 62000
                   COMPUTE WS-RATE = 0.0090
               WHEN WS-AMOUNT <= 78000
                   COMPUTE WS-RATE = 0.0071
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0061
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
