       IDENTIFICATION DIVISION.
       PROGRAM-ID. STATUS-CODE-MAP.
      *---------------------------------------------------------------
      * Status code mapping with EVALUATE
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TRANSACTION-ID   PIC X(12)    VALUE 'TXN-20240301'.
       01  WS-RETURN-CODE      PIC 9(4)     VALUE 2010.
       01  WS-STATUS-TEXT      PIC X(30)    VALUE SPACES.
       01  WS-SEVERITY         PIC X(8)     VALUE SPACES.
       01  WS-RETRY-FLAG       PIC X        VALUE 'N'.
       01  WS-LOG-LEVEL        PIC 9        VALUE ZEROS.
       01  WS-NOTIFY-FLAG      PIC X        VALUE 'N'.
       01  WS-ACTION-CODE      PIC X(15)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE WS-RETURN-CODE
               WHEN 0
                   MOVE 'SUCCESS' TO WS-STATUS-TEXT
                   MOVE 'INFO' TO WS-SEVERITY
                   MOVE 1 TO WS-LOG-LEVEL
                   MOVE 'CONTINUE' TO WS-ACTION-CODE
               WHEN 1001
                   MOVE 'INVALID ACCOUNT' TO WS-STATUS-TEXT
                   MOVE 'ERROR' TO WS-SEVERITY
                   MOVE 3 TO WS-LOG-LEVEL
                   MOVE 'REJECT' TO WS-ACTION-CODE
               WHEN 1002
                   MOVE 'INSUFFICIENT FUNDS' TO WS-STATUS-TEXT
                   MOVE 'ERROR' TO WS-SEVERITY
                   MOVE 3 TO WS-LOG-LEVEL
                   MOVE 'REJECT' TO WS-ACTION-CODE
               WHEN 2001
                   MOVE 'TIMEOUT - DB CONN' TO WS-STATUS-TEXT
                   MOVE 'WARNING' TO WS-SEVERITY
                   MOVE 'Y' TO WS-RETRY-FLAG
                   MOVE 4 TO WS-LOG-LEVEL
                   MOVE 'RETRY' TO WS-ACTION-CODE
               WHEN 2010
                   MOVE 'TIMEOUT - EXT SERVICE' TO WS-STATUS-TEXT
                   MOVE 'WARNING' TO WS-SEVERITY
                   MOVE 'Y' TO WS-RETRY-FLAG
                   MOVE 4 TO WS-LOG-LEVEL
                   MOVE 'RETRY' TO WS-ACTION-CODE
               WHEN 3001
                   MOVE 'SYSTEM UNAVAILABLE' TO WS-STATUS-TEXT
                   MOVE 'CRITICAL' TO WS-SEVERITY
                   MOVE 'Y' TO WS-NOTIFY-FLAG
                   MOVE 5 TO WS-LOG-LEVEL
                   MOVE 'ESCALATE' TO WS-ACTION-CODE
               WHEN 3002
                   MOVE 'DATA CORRUPTION' TO WS-STATUS-TEXT
                   MOVE 'CRITICAL' TO WS-SEVERITY
                   MOVE 'Y' TO WS-NOTIFY-FLAG
                   MOVE 5 TO WS-LOG-LEVEL
                   MOVE 'HALT' TO WS-ACTION-CODE
               WHEN 4001
                   MOVE 'DUPLICATE TRANS' TO WS-STATUS-TEXT
                   MOVE 'WARNING' TO WS-SEVERITY
                   MOVE 2 TO WS-LOG-LEVEL
                   MOVE 'SKIP' TO WS-ACTION-CODE
               WHEN OTHER
                   MOVE 'UNKNOWN ERROR' TO WS-STATUS-TEXT
                   MOVE 'ERROR' TO WS-SEVERITY
                   MOVE 'Y' TO WS-NOTIFY-FLAG
                   MOVE 4 TO WS-LOG-LEVEL
                   MOVE 'INVESTIGATE' TO WS-ACTION-CODE
           END-EVALUATE
           DISPLAY 'TRANS:    ' WS-TRANSACTION-ID
           DISPLAY 'CODE:     ' WS-RETURN-CODE
           DISPLAY 'STATUS:   ' WS-STATUS-TEXT
           DISPLAY 'SEVERITY: ' WS-SEVERITY
           DISPLAY 'ACTION:   ' WS-ACTION-CODE
           DISPLAY 'RETRY:    ' WS-RETRY-FLAG
           DISPLAY 'NOTIFY:   ' WS-NOTIFY-FLAG
           STOP RUN.
