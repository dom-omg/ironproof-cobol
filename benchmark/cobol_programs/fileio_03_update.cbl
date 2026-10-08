       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILEIO-UPDATE.
      *---------------------------------------------------------------
      * File update pattern - apply price adjustments
      *---------------------------------------------------------------
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT PRICE-FILE
               ASSIGN TO 'PRICES.DAT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-PRICE-STATUS.
           SELECT ADJUST-FILE
               ASSIGN TO 'ADJUST.DAT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-ADJ-STATUS.
           SELECT UPDATED-FILE
               ASSIGN TO 'NEWPRICES.DAT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-UPD-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  PRICE-FILE.
       01  PRICE-RECORD.
           05  PR-PRODUCT-ID   PIC X(8).
           05  PR-DESCRIPTION  PIC X(20).
           05  PR-CURRENT-PRICE PIC 9(6)V99.
           05  PR-CATEGORY     PIC X(3).
       FD  ADJUST-FILE.
       01  ADJUST-RECORD.
           05  AJ-PRODUCT-ID   PIC X(8).
           05  AJ-ADJUST-TYPE  PIC X.
           05  AJ-ADJUST-VALUE PIC 9(3)V99.
       FD  UPDATED-FILE.
       01  UPDATED-RECORD.
           05  UR-PRODUCT-ID   PIC X(8).
           05  UR-DESCRIPTION  PIC X(20).
           05  UR-OLD-PRICE    PIC 9(6)V99.
           05  UR-NEW-PRICE    PIC 9(6)V99.
           05  UR-CHANGE-FLAG  PIC X.
       WORKING-STORAGE SECTION.
       01  WS-PRICE-STATUS     PIC X(2)     VALUE SPACES.
       01  WS-ADJ-STATUS       PIC X(2)     VALUE SPACES.
       01  WS-UPD-STATUS       PIC X(2)     VALUE SPACES.
       01  WS-EOF-PRICE        PIC X        VALUE 'N'.
       01  WS-UPDATED-COUNT    PIC 9(5)     VALUE ZEROS.
       01  WS-UNCHANGED-COUNT  PIC 9(5)     VALUE ZEROS.
       01  WS-NEW-PRICE        PIC 9(6)V99  VALUE ZEROS.
       01  WS-ADJUST-PCT       PIC 9V9999   VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           OPEN INPUT PRICE-FILE
           OPEN INPUT ADJUST-FILE
           OPEN OUTPUT UPDATED-FILE
           PERFORM PROCESS-PRICES
               UNTIL WS-EOF-PRICE = 'Y'
           CLOSE PRICE-FILE
           CLOSE ADJUST-FILE
           CLOSE UPDATED-FILE
           DISPLAY 'UPDATED:   ' WS-UPDATED-COUNT
           DISPLAY 'UNCHANGED: ' WS-UNCHANGED-COUNT
           STOP RUN.

       PROCESS-PRICES.
           READ PRICE-FILE
               AT END
                   MOVE 'Y' TO WS-EOF-PRICE
               NOT AT END
                   PERFORM APPLY-ADJUSTMENT
           END-READ.

       APPLY-ADJUSTMENT.
           MOVE PR-PRODUCT-ID TO UR-PRODUCT-ID
           MOVE PR-DESCRIPTION TO UR-DESCRIPTION
           MOVE PR-CURRENT-PRICE TO UR-OLD-PRICE
           EVALUATE PR-CATEGORY
               WHEN 'ELC'
                   COMPUTE WS-NEW-PRICE =
                       PR-CURRENT-PRICE * 1.05
                   MOVE 'Y' TO UR-CHANGE-FLAG
               WHEN 'FUR'
                   COMPUTE WS-NEW-PRICE =
                       PR-CURRENT-PRICE * 0.90
                   MOVE 'Y' TO UR-CHANGE-FLAG
               WHEN 'CLO'
                   COMPUTE WS-NEW-PRICE =
                       PR-CURRENT-PRICE * 1.03
                   MOVE 'Y' TO UR-CHANGE-FLAG
               WHEN OTHER
                   MOVE PR-CURRENT-PRICE TO WS-NEW-PRICE
                   MOVE 'N' TO UR-CHANGE-FLAG
           END-EVALUATE
           MOVE WS-NEW-PRICE TO UR-NEW-PRICE
           WRITE UPDATED-RECORD
           IF UR-CHANGE-FLAG = 'Y'
               ADD 1 TO WS-UPDATED-COUNT
           ELSE
               ADD 1 TO WS-UNCHANGED-COUNT
           END-IF.
