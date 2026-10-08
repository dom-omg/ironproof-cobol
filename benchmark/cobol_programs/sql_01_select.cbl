       IDENTIFICATION DIVISION.
       PROGRAM-ID. SQL-SELECT.
      *---------------------------------------------------------------
      * EXEC SQL SELECT INTO - customer account lookup
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-ACCT-NUMBER      PIC X(10)    VALUE '1000456789'.
       01  WS-CUST-NAME        PIC X(30)    VALUE SPACES.
       01  WS-BALANCE          PIC S9(11)V99 VALUE ZEROS.
       01  WS-ACCT-TYPE        PIC X(3)     VALUE SPACES.
       01  WS-OPEN-DATE        PIC X(10)    VALUE SPACES.
       01  WS-STATUS-CODE      PIC X(2)     VALUE SPACES.
       01  WS-BRANCH-ID        PIC X(6)     VALUE SPACES.
       01  WS-SQLCODE          PIC S9(9)    VALUE ZEROS.
       01  WS-TRANS-COUNT      PIC 9(6)     VALUE ZEROS.
       01  WS-LAST-TRANS-DATE  PIC X(10)    VALUE SPACES.
       01  WS-ERROR-MSG        PIC X(40)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EXEC SQL
               SELECT CUSTOMER_NAME,
                      ACCOUNT_BALANCE,
                      ACCOUNT_TYPE,
                      OPEN_DATE,
                      STATUS_CODE,
                      BRANCH_ID
               INTO  :WS-CUST-NAME,
                     :WS-BALANCE,
                     :WS-ACCT-TYPE,
                     :WS-OPEN-DATE,
                     :WS-STATUS-CODE,
                     :WS-BRANCH-ID
               FROM  CUSTOMER_ACCOUNTS
               WHERE ACCOUNT_NUMBER = :WS-ACCT-NUMBER
           END-EXEC
           IF WS-SQLCODE = 0
               DISPLAY 'ACCOUNT:  ' WS-ACCT-NUMBER
               DISPLAY 'NAME:     ' WS-CUST-NAME
               DISPLAY 'BALANCE:  ' WS-BALANCE
               DISPLAY 'TYPE:     ' WS-ACCT-TYPE
               DISPLAY 'OPENED:   ' WS-OPEN-DATE
               DISPLAY 'STATUS:   ' WS-STATUS-CODE
               DISPLAY 'BRANCH:   ' WS-BRANCH-ID
           ELSE IF WS-SQLCODE = 100
               MOVE 'ACCOUNT NOT FOUND' TO WS-ERROR-MSG
               DISPLAY 'ERROR: ' WS-ERROR-MSG
           ELSE
               MOVE 'DATABASE ERROR' TO WS-ERROR-MSG
               DISPLAY 'ERROR: ' WS-ERROR-MSG
               DISPLAY 'SQLCODE: ' WS-SQLCODE
           END-IF
           EXEC SQL
               SELECT COUNT(*),
                      MAX(TRANS_DATE)
               INTO  :WS-TRANS-COUNT,
                     :WS-LAST-TRANS-DATE
               FROM  TRANSACTIONS
               WHERE ACCOUNT_NUMBER = :WS-ACCT-NUMBER
           END-EXEC
           IF WS-SQLCODE = 0
               DISPLAY 'TRANS COUNT: ' WS-TRANS-COUNT
               DISPLAY 'LAST TRANS:  ' WS-LAST-TRANS-DATE
           END-IF
           STOP RUN.
