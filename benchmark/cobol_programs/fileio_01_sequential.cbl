       IDENTIFICATION DIVISION.
       PROGRAM-ID. FILEIO-SEQUENTIAL.
      *---------------------------------------------------------------
      * Sequential file read/write - customer transaction log
      *---------------------------------------------------------------
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INPUT-FILE
               ASSIGN TO 'TRANSIN.DAT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-INPUT-STATUS.
           SELECT OUTPUT-FILE
               ASSIGN TO 'TRANSOUT.DAT'
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-OUTPUT-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  INPUT-FILE.
       01  INPUT-RECORD.
           05  IR-ACCT-NUM     PIC X(10).
           05  IR-TRANS-TYPE   PIC X(2).
           05  IR-AMOUNT       PIC 9(8)V99.
           05  IR-DATE         PIC 9(8).
       FD  OUTPUT-FILE.
       01  OUTPUT-RECORD.
           05  OR-ACCT-NUM     PIC X(10).
           05  OR-TRANS-TYPE   PIC X(2).
           05  OR-AMOUNT       PIC 9(8)V99.
           05  OR-DATE         PIC 9(8).
           05  OR-STATUS       PIC X(3).
       WORKING-STORAGE SECTION.
       01  WS-INPUT-STATUS     PIC X(2)     VALUE SPACES.
       01  WS-OUTPUT-STATUS    PIC X(2)     VALUE SPACES.
       01  WS-EOF-FLAG         PIC X        VALUE 'N'.
       01  WS-READ-COUNT       PIC 9(6)     VALUE ZEROS.
       01  WS-WRITE-COUNT      PIC 9(6)     VALUE ZEROS.
       01  WS-ERROR-COUNT      PIC 9(4)     VALUE ZEROS.
       01  WS-TOTAL-DEBITS     PIC 9(10)V99 VALUE ZEROS.
       01  WS-TOTAL-CREDITS    PIC 9(10)V99 VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           OPEN INPUT INPUT-FILE
           OPEN OUTPUT OUTPUT-FILE
           IF WS-INPUT-STATUS = '00'
               PERFORM READ-PROCESS-WRITE
                   UNTIL WS-EOF-FLAG = 'Y'
           END-IF
           CLOSE INPUT-FILE
           CLOSE OUTPUT-FILE
           DISPLAY 'RECORDS READ:    ' WS-READ-COUNT
           DISPLAY 'RECORDS WRITTEN: ' WS-WRITE-COUNT
           DISPLAY 'ERRORS:          ' WS-ERROR-COUNT
           DISPLAY 'TOTAL DEBITS:    ' WS-TOTAL-DEBITS
           DISPLAY 'TOTAL CREDITS:   ' WS-TOTAL-CREDITS
           STOP RUN.

       READ-PROCESS-WRITE.
           READ INPUT-FILE
               AT END
                   MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END
                   ADD 1 TO WS-READ-COUNT
                   PERFORM PROCESS-RECORD
           END-READ.

       PROCESS-RECORD.
           MOVE IR-ACCT-NUM TO OR-ACCT-NUM
           MOVE IR-TRANS-TYPE TO OR-TRANS-TYPE
           MOVE IR-AMOUNT TO OR-AMOUNT
           MOVE IR-DATE TO OR-DATE
           IF IR-AMOUNT > 0
               MOVE 'OK ' TO OR-STATUS
               IF IR-TRANS-TYPE = 'DB'
                   ADD IR-AMOUNT TO WS-TOTAL-DEBITS
               ELSE IF IR-TRANS-TYPE = 'CR'
                   ADD IR-AMOUNT TO WS-TOTAL-CREDITS
               END-IF
               WRITE OUTPUT-RECORD
               ADD 1 TO WS-WRITE-COUNT
           ELSE
               MOVE 'ERR' TO OR-STATUS
               WRITE OUTPUT-RECORD
               ADD 1 TO WS-ERROR-COUNT
           END-IF.
