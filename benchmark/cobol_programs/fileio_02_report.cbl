       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILEIO-REPORT.
      *---------------------------------------------------------------
      * Report generation from file - monthly account summary
      *---------------------------------------------------------------
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-FILE
               ASSIGN TO 'ACCOUNTS.DAT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
           SELECT REPORT-FILE
               ASSIGN TO 'ACCTRPT.RPT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-RPT-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-FILE.
       01  ACCT-RECORD.
           05  AR-ACCT-NUM     PIC X(10).
           05  AR-NAME         PIC X(25).
           05  AR-BALANCE      PIC S9(9)V99.
           05  AR-TYPE         PIC X.
       FD  REPORT-FILE.
       01  REPORT-LINE         PIC X(80).
       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS      PIC X(2)     VALUE SPACES.
       01  WS-RPT-STATUS       PIC X(2)     VALUE SPACES.
       01  WS-EOF              PIC X        VALUE 'N'.
       01  WS-RECORD-CTR       PIC 9(5)     VALUE ZEROS.
       01  WS-TOTAL-BALANCE    PIC S9(12)V99 VALUE ZEROS.
       01  WS-CHEQUING-BAL     PIC S9(12)V99 VALUE ZEROS.
       01  WS-SAVINGS-BAL      PIC S9(12)V99 VALUE ZEROS.
       01  WS-CHEQUING-CNT     PIC 9(5)     VALUE ZEROS.
       01  WS-SAVINGS-CNT      PIC 9(5)     VALUE ZEROS.
       01  WS-HEADER-LINE.
           05  FILLER           PIC X(10)    VALUE 'ACCOUNT'.
           05  FILLER           PIC X(3)     VALUE '   '.
           05  FILLER           PIC X(25)    VALUE 'NAME'.
           05  FILLER           PIC X(3)     VALUE '   '.
           05  FILLER           PIC X(12)    VALUE 'BALANCE'.
           05  FILLER           PIC X(3)     VALUE '   '.
           05  FILLER           PIC X(4)     VALUE 'TYPE'.
       01  WS-DETAIL-LINE.
           05  WS-DL-ACCT      PIC X(10)    VALUE SPACES.
           05  FILLER           PIC X(3)     VALUE '   '.
           05  WS-DL-NAME      PIC X(25)    VALUE SPACES.
           05  FILLER           PIC X(3)     VALUE '   '.
           05  WS-DL-BALANCE   PIC Z(9)9.99 VALUE ZEROS.
           05  FILLER           PIC X(3)     VALUE '   '.
           05  WS-DL-TYPE      PIC X(4)     VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           OPEN INPUT ACCT-FILE
           OPEN OUTPUT REPORT-FILE
           MOVE WS-HEADER-LINE TO REPORT-LINE
           WRITE REPORT-LINE
           PERFORM READ-AND-REPORT
               UNTIL WS-EOF = 'Y'
           PERFORM WRITE-SUMMARY
           CLOSE ACCT-FILE
           CLOSE REPORT-FILE
           STOP RUN.

       READ-AND-REPORT.
           READ ACCT-FILE
               AT END
                   MOVE 'Y' TO WS-EOF
               NOT AT END
                   ADD 1 TO WS-RECORD-CTR
                   PERFORM FORMAT-DETAIL
           END-READ.

       FORMAT-DETAIL.
           MOVE AR-ACCT-NUM TO WS-DL-ACCT
           MOVE AR-NAME TO WS-DL-NAME
           MOVE AR-BALANCE TO WS-DL-BALANCE
           ADD AR-BALANCE TO WS-TOTAL-BALANCE
           IF AR-TYPE = 'C'
               MOVE 'CHQ ' TO WS-DL-TYPE
               ADD AR-BALANCE TO WS-CHEQUING-BAL
               ADD 1 TO WS-CHEQUING-CNT
           ELSE
               MOVE 'SAV ' TO WS-DL-TYPE
               ADD AR-BALANCE TO WS-SAVINGS-BAL
               ADD 1 TO WS-SAVINGS-CNT
           END-IF
           MOVE WS-DETAIL-LINE TO REPORT-LINE
           WRITE REPORT-LINE.

       WRITE-SUMMARY.
           MOVE SPACES TO REPORT-LINE
           WRITE REPORT-LINE
           DISPLAY 'TOTAL ACCOUNTS:  ' WS-RECORD-CTR
           DISPLAY 'TOTAL BALANCE:   ' WS-TOTAL-BALANCE
           DISPLAY 'CHEQUING COUNT:  ' WS-CHEQUING-CNT
           DISPLAY 'CHEQUING BAL:    ' WS-CHEQUING-BAL
           DISPLAY 'SAVINGS COUNT:   ' WS-SAVINGS-CNT
           DISPLAY 'SAVINGS BAL:     ' WS-SAVINGS-BAL.
