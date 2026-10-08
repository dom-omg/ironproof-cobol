       IDENTIFICATION DIVISION.
       PROGRAM-ID. SQL-CURSOR.
      *---------------------------------------------------------------
      * EXEC SQL with cursor pattern - monthly statement generation
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ACCT-NUMBER      PIC X(10)    VALUE '1000456789'.
       01  WS-START-DATE       PIC X(10)    VALUE '2024-03-01'.
       01  WS-END-DATE         PIC X(10)    VALUE '2024-03-31'.
       01  WS-SQLCODE          PIC S9(9)    VALUE ZEROS.
       01  WS-CURSOR-OPEN      PIC X        VALUE 'N'.
       01  WS-TRANS-REC.
           05  WS-TR-ID        PIC X(15)    VALUE SPACES.
           05  WS-TR-DATE      PIC X(10)    VALUE SPACES.
           05  WS-TR-TYPE      PIC X(4)     VALUE SPACES.
           05  WS-TR-AMOUNT    PIC S9(8)V99 VALUE ZEROS.
           05  WS-TR-DESC      PIC X(30)    VALUE SPACES.
       01  WS-TOTAL-DEBITS     PIC 9(10)V99 VALUE ZEROS.
       01  WS-TOTAL-CREDITS    PIC 9(10)V99 VALUE ZEROS.
       01  WS-TRANS-COUNT      PIC 9(5)     VALUE ZEROS.
       01  WS-NET-CHANGE       PIC S9(10)V99 VALUE ZEROS.
       01  WS-OPENING-BAL      PIC S9(11)V99 VALUE ZEROS.
       01  WS-CLOSING-BAL      PIC S9(11)V99 VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EXEC SQL
               SELECT ACCOUNT_BALANCE
               INTO :WS-OPENING-BAL
               FROM CUSTOMER_ACCOUNTS
               WHERE ACCOUNT_NUMBER = :WS-ACCT-NUMBER
           END-EXEC
           EXEC SQL
               DECLARE TRANS_CURSOR CURSOR FOR
               SELECT TRANS_ID,
                      TRANS_DATE,
                      TRANS_TYPE,
                      TRANS_AMOUNT,
                      DESCRIPTION
               FROM   TRANSACTIONS
               WHERE  ACCOUNT_NUMBER = :WS-ACCT-NUMBER
               AND    TRANS_DATE BETWEEN :WS-START-DATE
                      AND :WS-END-DATE
               ORDER BY TRANS_DATE
           END-EXEC
           EXEC SQL
               OPEN TRANS_CURSOR
           END-EXEC
           IF WS-SQLCODE = 0
               MOVE 'Y' TO WS-CURSOR-OPEN
               PERFORM FETCH-TRANSACTION
                   UNTIL WS-SQLCODE NOT = 0
           END-IF
           IF WS-CURSOR-OPEN = 'Y'
               EXEC SQL
                   CLOSE TRANS_CURSOR
               END-EXEC
           END-IF
           COMPUTE WS-NET-CHANGE =
               WS-TOTAL-CREDITS - WS-TOTAL-DEBITS
           COMPUTE WS-CLOSING-BAL =
               WS-OPENING-BAL + WS-NET-CHANGE
           DISPLAY 'ACCOUNT:     ' WS-ACCT-NUMBER
           DISPLAY 'PERIOD:      ' WS-START-DATE
               ' TO ' WS-END-DATE
           DISPLAY 'TRANS COUNT: ' WS-TRANS-COUNT
           DISPLAY 'DEBITS:      ' WS-TOTAL-DEBITS
           DISPLAY 'CREDITS:     ' WS-TOTAL-CREDITS
           DISPLAY 'NET CHANGE:  ' WS-NET-CHANGE
           DISPLAY 'OPENING BAL: ' WS-OPENING-BAL
           DISPLAY 'CLOSING BAL: ' WS-CLOSING-BAL
           STOP RUN.

       FETCH-TRANSACTION.
           EXEC SQL
               FETCH TRANS_CURSOR
               INTO :WS-TR-ID,
                    :WS-TR-DATE,
                    :WS-TR-TYPE,
                    :WS-TR-AMOUNT,
                    :WS-TR-DESC
           END-EXEC
           IF WS-SQLCODE = 0
               ADD 1 TO WS-TRANS-COUNT
               IF WS-TR-TYPE = 'DEBI'
                   ADD WS-TR-AMOUNT TO WS-TOTAL-DEBITS
               ELSE
                   ADD WS-TR-AMOUNT TO WS-TOTAL-CREDITS
               END-IF
               DISPLAY WS-TR-DATE ' '
                   WS-TR-TYPE ' '
                   WS-TR-AMOUNT ' '
                   WS-TR-DESC
           END-IF.
