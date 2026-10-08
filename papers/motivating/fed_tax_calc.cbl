       IDENTIFICATION DIVISION.
       PROGRAM-ID. FED-TAX-CALC.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 INCOME   PIC 9(8)V99.
       01 TAX-RATE PIC V9(4).
       01 TAX-AMT  PIC 9(8)V99.
       PROCEDURE DIVISION.
           EVALUATE TRUE
               WHEN INCOME <= 47150
                   COMPUTE TAX-RATE = 0.12
               WHEN INCOME <= 100525
                   COMPUTE TAX-RATE = 0.22
               WHEN INCOME <= 191950
                   COMPUTE TAX-RATE = 0.24
               WHEN OTHER
                   COMPUTE TAX-RATE = 0.32
           END-EVALUATE
           COMPUTE TAX-AMT = INCOME * TAX-RATE
           STOP RUN.
