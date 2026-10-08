       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-153.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6422.16.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 11000
                   COMPUTE WS-RATE = 0.0075
               WHEN WS-AMOUNT <= 20000
                   COMPUTE WS-RATE = 0.0085
               WHEN WS-AMOUNT <= 43000
                   COMPUTE WS-RATE = 0.0019
               WHEN WS-AMOUNT <= 78000
                   COMPUTE WS-RATE = 0.0045
               WHEN WS-AMOUNT <= 85000
                   COMPUTE WS-RATE = 0.0040
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0084
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
