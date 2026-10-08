       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-148.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 9509.70.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 12000
                   COMPUTE WS-RATE = 0.0077
               WHEN WS-AMOUNT <= 79000
                   COMPUTE WS-RATE = 0.0065
               WHEN WS-AMOUNT <= 83000
                   COMPUTE WS-RATE = 0.0050
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0060
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
