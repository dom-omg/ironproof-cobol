       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-198.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 5512.64.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 18000
                   COMPUTE WS-RATE = 0.0041
               WHEN WS-AMOUNT <= 20000
                   COMPUTE WS-RATE = 0.0021
               WHEN WS-AMOUNT <= 42000
                   COMPUTE WS-RATE = 0.0051
               WHEN WS-AMOUNT <= 66000
                   COMPUTE WS-RATE = 0.0079
               WHEN WS-AMOUNT <= 78000
                   COMPUTE WS-RATE = 0.0095
               WHEN WS-AMOUNT <= 79000
                   COMPUTE WS-RATE = 0.0039
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0076
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
