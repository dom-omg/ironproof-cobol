       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-194.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6607.46.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 14000
                   COMPUTE WS-RATE = 0.0034
               WHEN WS-AMOUNT <= 18000
                   COMPUTE WS-RATE = 0.0094
               WHEN WS-AMOUNT <= 56000
                   COMPUTE WS-RATE = 0.0047
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0098
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
