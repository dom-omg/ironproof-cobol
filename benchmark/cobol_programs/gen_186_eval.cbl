       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-186.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 9915.43.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 12000
                   COMPUTE WS-RATE = 0.0022
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0076
               WHEN WS-AMOUNT <= 69000
                   COMPUTE WS-RATE = 0.0075
               WHEN WS-AMOUNT <= 79000
                   COMPUTE WS-RATE = 0.0020
               WHEN WS-AMOUNT <= 83000
                   COMPUTE WS-RATE = 0.0022
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0085
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
