       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOOP-PARAGRAPH.
      *---------------------------------------------------------------
      * PERFORM paragraph-name - batch processing pipeline
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-BATCH-ID         PIC X(10)    VALUE 'BAT-002451'.
       01  WS-RECORD-COUNT     PIC 9(5)     VALUE ZEROS.
       01  WS-VALID-COUNT      PIC 9(5)     VALUE ZEROS.
       01  WS-ERROR-COUNT      PIC 9(5)     VALUE ZEROS.
       01  WS-TOTAL-AMOUNT     PIC 9(9)V99  VALUE ZEROS.
       01  WS-CURRENT-AMT      PIC 9(6)V99  VALUE ZEROS.
       01  WS-STATUS           PIC X(10)    VALUE SPACES.
       01  WS-PROCESS-FLAG     PIC X        VALUE 'Y'.
       01  WS-AVG-AMOUNT       PIC 9(6)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           PERFORM INIT-BATCH
           PERFORM VALIDATE-BATCH
           PERFORM PROCESS-RECORDS
           PERFORM CALC-SUMMARY
           PERFORM DISPLAY-RESULTS
           STOP RUN.

       INIT-BATCH.
           MOVE ZEROS TO WS-RECORD-COUNT
           MOVE ZEROS TO WS-VALID-COUNT
           MOVE ZEROS TO WS-ERROR-COUNT
           MOVE ZEROS TO WS-TOTAL-AMOUNT
           MOVE 'STARTING' TO WS-STATUS
           DISPLAY 'BATCH ' WS-BATCH-ID ' INITIALIZED'.

       VALIDATE-BATCH.
           IF WS-BATCH-ID = SPACES
               MOVE 'N' TO WS-PROCESS-FLAG
               MOVE 'INVALID' TO WS-STATUS
           ELSE
               MOVE 'Y' TO WS-PROCESS-FLAG
               MOVE 'VALIDATED' TO WS-STATUS
           END-IF.

       PROCESS-RECORDS.
           IF WS-PROCESS-FLAG = 'Y'
               MOVE 250.00 TO WS-CURRENT-AMT
               PERFORM ADD-RECORD
               MOVE 175.50 TO WS-CURRENT-AMT
               PERFORM ADD-RECORD
               MOVE 0.00 TO WS-CURRENT-AMT
               PERFORM ADD-RECORD
               MOVE 890.25 TO WS-CURRENT-AMT
               PERFORM ADD-RECORD
               MOVE 425.00 TO WS-CURRENT-AMT
               PERFORM ADD-RECORD
               MOVE 'PROCESSED' TO WS-STATUS
           END-IF.

       ADD-RECORD.
           ADD 1 TO WS-RECORD-COUNT
           IF WS-CURRENT-AMT > 0
               ADD WS-CURRENT-AMT TO WS-TOTAL-AMOUNT
               ADD 1 TO WS-VALID-COUNT
           ELSE
               ADD 1 TO WS-ERROR-COUNT
           END-IF.

       CALC-SUMMARY.
           IF WS-VALID-COUNT > 0
               DIVIDE WS-TOTAL-AMOUNT BY WS-VALID-COUNT
                   GIVING WS-AVG-AMOUNT
           END-IF
           MOVE 'COMPLETED' TO WS-STATUS.

       DISPLAY-RESULTS.
           DISPLAY 'BATCH:    ' WS-BATCH-ID
           DISPLAY 'STATUS:   ' WS-STATUS
           DISPLAY 'RECORDS:  ' WS-RECORD-COUNT
           DISPLAY 'VALID:    ' WS-VALID-COUNT
           DISPLAY 'ERRORS:   ' WS-ERROR-COUNT
           DISPLAY 'TOTAL:    ' WS-TOTAL-AMOUNT
           DISPLAY 'AVERAGE:  ' WS-AVG-AMOUNT.
