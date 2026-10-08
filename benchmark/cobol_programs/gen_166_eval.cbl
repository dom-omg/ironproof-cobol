       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-166.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 7033.00.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 66000
                   COMPUTE WS-RATE = 0.0031
               WHEN WS-AMOUNT <= 74000
                   COMPUTE WS-RATE = 0.0092
               WHEN WS-AMOUNT <= 81000
                   COMPUTE WS-RATE = 0.0019
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0038
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
