       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-143.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 3987.55.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 3000
                   COMPUTE WS-RATE = 0.0080
               WHEN WS-AMOUNT <= 15000
                   COMPUTE WS-RATE = 0.0059
               WHEN WS-AMOUNT <= 22000
                   COMPUTE WS-RATE = 0.0089
               WHEN WS-AMOUNT <= 38000
                   COMPUTE WS-RATE = 0.0047
               WHEN WS-AMOUNT <= 42000
                   COMPUTE WS-RATE = 0.0012
               WHEN WS-AMOUNT <= 52000
                   COMPUTE WS-RATE = 0.0056
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0014
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
