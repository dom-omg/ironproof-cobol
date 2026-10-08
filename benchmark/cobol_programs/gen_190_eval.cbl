       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-190.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 5229.30.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 17000
                   COMPUTE WS-RATE = 0.0098
               WHEN WS-AMOUNT <= 41000
                   COMPUTE WS-RATE = 0.0048
               WHEN WS-AMOUNT <= 45000
                   COMPUTE WS-RATE = 0.0066
               WHEN WS-AMOUNT <= 52000
                   COMPUTE WS-RATE = 0.0072
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0014
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
