       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-176.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 6002.46.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 4000
                   COMPUTE WS-RATE = 0.0078
               WHEN WS-AMOUNT <= 19000
                   COMPUTE WS-RATE = 0.0087
               WHEN WS-AMOUNT <= 21000
                   COMPUTE WS-RATE = 0.0057
               WHEN WS-AMOUNT <= 47000
                   COMPUTE WS-RATE = 0.0005
               WHEN WS-AMOUNT <= 66000
                   COMPUTE WS-RATE = 0.0017
               WHEN WS-AMOUNT <= 87000
                   COMPUTE WS-RATE = 0.0009
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0031
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
