       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-EVAL-188.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-AMOUNT            PIC 9(6)V99  VALUE 4874.58.
       01  WS-RATE              PIC V9(4)    VALUE ZEROS.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AMOUNT <= 4000
                   COMPUTE WS-RATE = 0.0038
               WHEN WS-AMOUNT <= 64000
                   COMPUTE WS-RATE = 0.0083
               WHEN WS-AMOUNT <= 70000
                   COMPUTE WS-RATE = 0.0039
               WHEN WS-AMOUNT <= 80000
                   COMPUTE WS-RATE = 0.0062
               WHEN WS-AMOUNT <= 81000
                   COMPUTE WS-RATE = 0.0032
               WHEN WS-AMOUNT <= 82000
                   COMPUTE WS-RATE = 0.0088
               WHEN OTHER
                   COMPUTE WS-RATE = 0.0052
           END-EVALUATE
           COMPUTE WS-RESULT = WS-AMOUNT * WS-RATE
           STOP RUN.
