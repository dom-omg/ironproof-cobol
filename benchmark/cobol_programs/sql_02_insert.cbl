       IDENTIFICATION DIVISION.
       PROGRAM-ID. SQL-INSERT.
      *---------------------------------------------------------------
      * EXEC SQL INSERT - new transaction record creation
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TRANS-ID         PIC X(15)    VALUE SPACES.
       01  WS-ACCT-NUMBER      PIC X(10)    VALUE '1000456789'.
       01  WS-TRANS-TYPE       PIC X(4)     VALUE 'DEBI'.
       01  WS-TRANS-AMOUNT     PIC 9(8)V99  VALUE 1500.00.
       01  WS-TRANS-DATE       PIC X(10)    VALUE '2024-03-15'.
       01  WS-DESCRIPTION      PIC X(30)    VALUE 'HYDRO-QUEBEC PAYMENT'.
       01  WS-BRANCH-ID        PIC X(6)     VALUE 'MTL001'.
       01  WS-TELLER-ID        PIC X(6)     VALUE 'T00142'.
       01  WS-SQLCODE          PIC S9(9)    VALUE ZEROS.
       01  WS-CURRENT-BAL      PIC S9(11)V99 VALUE ZEROS.
       01  WS-NEW-BALANCE      PIC S9(11)V99 VALUE ZEROS.
       01  WS-INSERT-STATUS    PIC X(10)    VALUE SPACES.
       01  WS-SEQUENCE-NUM     PIC 9(10)    VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EXEC SQL
               SELECT NEXTVAL('TRANS_SEQ')
               INTO :WS-SEQUENCE-NUM
               FROM SYSIBM.SYSDUMMY1
           END-EXEC
           EXEC SQL
               SELECT ACCOUNT_BALANCE
               INTO :WS-CURRENT-BAL
               FROM CUSTOMER_ACCOUNTS
               WHERE ACCOUNT_NUMBER = :WS-ACCT-NUMBER
               FOR UPDATE
           END-EXEC
           IF WS-SQLCODE NOT = 0
               MOVE 'ACCT ERROR' TO WS-INSERT-STATUS
               DISPLAY 'ERROR: ACCOUNT LOOKUP FAILED'
               DISPLAY 'SQLCODE: ' WS-SQLCODE
               STOP RUN
           END-IF
           IF WS-TRANS-TYPE = 'DEBI'
               COMPUTE WS-NEW-BALANCE =
                   WS-CURRENT-BAL - WS-TRANS-AMOUNT
           ELSE
               COMPUTE WS-NEW-BALANCE =
                   WS-CURRENT-BAL + WS-TRANS-AMOUNT
           END-IF
           EXEC SQL
               INSERT INTO TRANSACTIONS
                   (TRANS_ID,
                    ACCOUNT_NUMBER,
                    TRANS_TYPE,
                    TRANS_AMOUNT,
                    TRANS_DATE,
                    DESCRIPTION,
                    BRANCH_ID,
                    TELLER_ID)
               VALUES
                   (:WS-SEQUENCE-NUM,
                    :WS-ACCT-NUMBER,
                    :WS-TRANS-TYPE,
                    :WS-TRANS-AMOUNT,
                    :WS-TRANS-DATE,
                    :WS-DESCRIPTION,
                    :WS-BRANCH-ID,
                    :WS-TELLER-ID)
           END-EXEC
           IF WS-SQLCODE = 0
               EXEC SQL
                   UPDATE CUSTOMER_ACCOUNTS
                   SET ACCOUNT_BALANCE = :WS-NEW-BALANCE
                   WHERE ACCOUNT_NUMBER = :WS-ACCT-NUMBER
               END-EXEC
               IF WS-SQLCODE = 0
                   EXEC SQL COMMIT END-EXEC
                   MOVE 'SUCCESS' TO WS-INSERT-STATUS
               ELSE
                   EXEC SQL ROLLBACK END-EXEC
                   MOVE 'UPD FAILED' TO WS-INSERT-STATUS
               END-IF
           ELSE
               EXEC SQL ROLLBACK END-EXEC
               MOVE 'INS FAILED' TO WS-INSERT-STATUS
           END-IF
           DISPLAY 'TRANS STATUS: ' WS-INSERT-STATUS
           DISPLAY 'OLD BALANCE:  ' WS-CURRENT-BAL
           DISPLAY 'NEW BALANCE:  ' WS-NEW-BALANCE
           STOP RUN.
