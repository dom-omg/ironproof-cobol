       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-169.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 5448.17.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 31000
                   COMPUTE WS-RATE = 0.0081
               WHEN WS-AMOUNT <= 45000
                   COMPUTE WS-RATE = 0.0014
               WHEN WS-AMOUNT <= 85000
                   COMPUTE WS-RATE = 0.0099
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0075
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
