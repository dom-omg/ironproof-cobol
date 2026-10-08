       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-202.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 8499.26.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 53000
                   COMPUTE WS-RATE = 0.0095
               WHEN WS-AMOUNT <= 61000
                   COMPUTE WS-RATE = 0.0094
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0008
               WHEN WS-AMOUNT <= 79000
                   COMPUTE WS-RATE = 0.0091
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0018
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
