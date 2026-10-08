       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-159.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 7874.47.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 21000
                   COMPUTE WS-RATE = 0.0026
               WHEN WS-AMOUNT <= 49000
                   COMPUTE WS-RATE = 0.0078
               WHEN WS-AMOUNT <= 54000
                   COMPUTE WS-RATE = 0.0018
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0033
               WHEN WS-AMOUNT <= 68000
                   COMPUTE WS-RATE = 0.0007
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0083
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
