       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-197.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 5457.60.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 26000
                   COMPUTE WS-RATE = 0.0065
               WHEN WS-AMOUNT <= 52000
                   COMPUTE WS-RATE = 0.0006
               WHEN WS-AMOUNT <= 66000
                   COMPUTE WS-RATE = 0.0006
               WHEN WS-AMOUNT <= 78000
                   COMPUTE WS-RATE = 0.0005
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0018
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
