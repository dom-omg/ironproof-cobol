       IDENTIFICATION DIVISION.
       PROGRAM-ID. DEPRECIATION-CALC.
      *---------------------------------------------------------------
      * Straight-line depreciation calculation
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ASSET-ID         PIC X(10)    VALUE 'AST-001542'.
       01  WS-ASSET-NAME       PIC X(20)    VALUE 'SERVER RACK UNIT'.
       01  WS-PURCHASE-COST    PIC 9(9)V99  VALUE 45000.00.
       01  WS-SALVAGE-VALUE    PIC 9(9)V99  VALUE 5000.00.
       01  WS-USEFUL-LIFE-YRS  PIC 9(2)     VALUE 7.
       01  WS-DEPRECIABLE-AMT  PIC 9(9)V99  VALUE ZEROS.
       01  WS-ANNUAL-DEPR      PIC 9(9)V99  VALUE ZEROS.
       01  WS-MONTHLY-DEPR     PIC 9(7)V99  VALUE ZEROS.
       01  WS-CURRENT-YEAR     PIC 9(2)     VALUE 3.
       01  WS-ACCUM-DEPR       PIC 9(9)V99  VALUE ZEROS.
       01  WS-BOOK-VALUE       PIC 9(9)V99  VALUE ZEROS.
       01  WS-DEPR-RATE        PIC 9V9999   VALUE ZEROS.
       01  WS-CTR              PIC 9(2)     VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-DEPRECIABLE-AMT =
               WS-PURCHASE-COST - WS-SALVAGE-VALUE
           IF WS-USEFUL-LIFE-YRS > 0
               COMPUTE WS-ANNUAL-DEPR =
                   WS-DEPRECIABLE-AMT / WS-USEFUL-LIFE-YRS
               COMPUTE WS-MONTHLY-DEPR =
                   WS-ANNUAL-DEPR / 12
               COMPUTE WS-DEPR-RATE =
                   1 / WS-USEFUL-LIFE-YRS
           END-IF
           MOVE ZEROS TO WS-ACCUM-DEPR
           MOVE 1 TO WS-CTR
           PERFORM ACCUMULATE-DEPR
               UNTIL WS-CTR > WS-CURRENT-YEAR
           COMPUTE WS-BOOK-VALUE =
               WS-PURCHASE-COST - WS-ACCUM-DEPR
           IF WS-BOOK-VALUE < WS-SALVAGE-VALUE
               MOVE WS-SALVAGE-VALUE TO WS-BOOK-VALUE
           END-IF
           DISPLAY 'ASSET:        ' WS-ASSET-ID
           DISPLAY 'NAME:         ' WS-ASSET-NAME
           DISPLAY 'COST:         ' WS-PURCHASE-COST
           DISPLAY 'ANNUAL DEPR:  ' WS-ANNUAL-DEPR
           DISPLAY 'ACCUM DEPR:   ' WS-ACCUM-DEPR
           DISPLAY 'BOOK VALUE:   ' WS-BOOK-VALUE
           STOP RUN.

       ACCUMULATE-DEPR.
           ADD WS-ANNUAL-DEPR TO WS-ACCUM-DEPR
           ADD 1 TO WS-CTR.
