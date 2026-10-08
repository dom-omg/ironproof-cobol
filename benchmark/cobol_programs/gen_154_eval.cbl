       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-154.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8625.11.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 40000
                   COMPUTE WS-RATE = 0.0083
               WHEN WS-AMOUNT <= 49000
                   COMPUTE WS-RATE = 0.0043
               WHEN WS-AMOUNT <= 72000
                   COMPUTE WS-RATE = 0.0017
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0086
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
