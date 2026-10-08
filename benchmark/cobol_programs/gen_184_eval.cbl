       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-184.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 5287.90.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 8000
                   COMPUTE WS-RATE = 0.0067
               WHEN WS-AMOUNT <= 16000
                   COMPUTE WS-RATE = 0.0020
               WHEN WS-AMOUNT <= 56000
                   COMPUTE WS-RATE = 0.0039
               WHEN WS-AMOUNT <= 65000
                   COMPUTE WS-RATE = 0.0022
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0021
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
