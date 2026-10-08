       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-165.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 9777.68.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 7000
                   COMPUTE WS-RATE = 0.0082
               WHEN WS-AMOUNT <= 16000
                   COMPUTE WS-RATE = 0.0080
               WHEN WS-AMOUNT <= 31000
                   COMPUTE WS-RATE = 0.0059
               WHEN WS-AMOUNT <= 39000
                   COMPUTE WS-RATE = 0.0009
               WHEN WS-AMOUNT <= 54000
                   COMPUTE WS-RATE = 0.0015
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0064
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
