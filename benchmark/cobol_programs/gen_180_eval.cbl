       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-180.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 2853.46.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 9000
                   COMPUTE WS-RATE = 0.0071
               WHEN WS-AMOUNT <= 12000
                   COMPUTE WS-RATE = 0.0070
               WHEN WS-AMOUNT <= 41000
                   COMPUTE WS-RATE = 0.0038
               WHEN WS-AMOUNT <= 45000
                   COMPUTE WS-RATE = 0.0039
               WHEN WS-AMOUNT <= 86000
                   COMPUTE WS-RATE = 0.0021
               WHEN WS-AMOUNT <= 88000
                   COMPUTE WS-RATE = 0.0092
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0091
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
