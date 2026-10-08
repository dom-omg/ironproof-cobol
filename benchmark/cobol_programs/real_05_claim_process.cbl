       IDENTIFICATION DIVISION.
       PROGRAM-ID. CLAIM-PROCESS.
      *---------------------------------------------------------------
      * Insurance claim processing with adjudication logic
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-CLAIM.
           05  WS-CLAIM-NUM    PIC X(12)    VALUE 'CLM-20240315'.
           05  WS-POLICY-NUM   PIC X(10)    VALUE 'POL-003421'.
           05  WS-CLAIM-TYPE   PIC X(4)     VALUE 'AUTO'.
           05  WS-CLAIM-DATE   PIC 9(8)     VALUE 20240315.
           05  WS-INCIDENT-DATE PIC 9(8)    VALUE 20240310.
           05  WS-CLAIM-AMOUNT PIC 9(8)V99  VALUE 15000.00.
       01  WS-POLICY.
           05  WS-POL-STATUS   PIC X(2)     VALUE 'AC'.
           05  WS-POL-EFF-DATE PIC 9(8)     VALUE 20230101.
           05  WS-POL-EXP-DATE PIC 9(8)     VALUE 20250101.
           05  WS-DEDUCTIBLE   PIC 9(5)V99  VALUE 500.00.
           05  WS-COVERAGE-MAX PIC 9(8)V99  VALUE 100000.00.
           05  WS-PREV-CLAIMS  PIC 9(2)     VALUE 1.
       01  WS-ADJUDICATION.
           05  WS-ADJ-STATUS   PIC X(10)    VALUE SPACES.
           05  WS-ADJ-REASON   PIC X(30)    VALUE SPACES.
           05  WS-PAYOUT-AMT   PIC 9(8)V99  VALUE ZEROS.
           05  WS-COPAY-PCT    PIC 9V99     VALUE ZEROS.
           05  WS-COPAY-AMT    PIC 9(6)V99  VALUE ZEROS.
           05  WS-NET-PAYOUT   PIC 9(8)V99  VALUE ZEROS.
           05  WS-PRIORITY     PIC X(6)     VALUE SPACES.
       01  WS-VALID-CLAIM      PIC X        VALUE 'Y'.
       01  WS-DAYS-DELAY       PIC 9(3)     VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           PERFORM VALIDATE-CLAIM
           IF WS-VALID-CLAIM = 'Y'
               PERFORM ADJUDICATE-CLAIM
               PERFORM CALCULATE-PAYOUT
           END-IF
           PERFORM DISPLAY-RESULT
           STOP RUN.

       VALIDATE-CLAIM.
           IF WS-POL-STATUS NOT = 'AC'
               MOVE 'N' TO WS-VALID-CLAIM
               MOVE 'DENIED' TO WS-ADJ-STATUS
               MOVE 'POLICY NOT ACTIVE' TO WS-ADJ-REASON
           END-IF
           IF WS-VALID-CLAIM = 'Y'
               AND WS-INCIDENT-DATE < WS-POL-EFF-DATE
               MOVE 'N' TO WS-VALID-CLAIM
               MOVE 'DENIED' TO WS-ADJ-STATUS
               MOVE 'INCIDENT BEFORE COVERAGE' TO WS-ADJ-REASON
           END-IF
           IF WS-VALID-CLAIM = 'Y'
               AND WS-INCIDENT-DATE > WS-POL-EXP-DATE
               MOVE 'N' TO WS-VALID-CLAIM
               MOVE 'DENIED' TO WS-ADJ-STATUS
               MOVE 'INCIDENT AFTER EXPIRY' TO WS-ADJ-REASON
           END-IF
           IF WS-VALID-CLAIM = 'Y'
               AND WS-CLAIM-AMOUNT <= 0
               MOVE 'N' TO WS-VALID-CLAIM
               MOVE 'DENIED' TO WS-ADJ-STATUS
               MOVE 'INVALID CLAIM AMOUNT' TO WS-ADJ-REASON
           END-IF
           IF WS-VALID-CLAIM = 'Y'
               COMPUTE WS-DAYS-DELAY =
                   WS-CLAIM-DATE - WS-INCIDENT-DATE
               IF WS-DAYS-DELAY > 90
                   MOVE 'N' TO WS-VALID-CLAIM
                   MOVE 'DENIED' TO WS-ADJ-STATUS
                   MOVE 'LATE FILING > 90 DAYS' TO WS-ADJ-REASON
               END-IF
           END-IF.

       ADJUDICATE-CLAIM.
           IF WS-CLAIM-AMOUNT > WS-COVERAGE-MAX
               MOVE WS-COVERAGE-MAX TO WS-PAYOUT-AMT
           ELSE
               MOVE WS-CLAIM-AMOUNT TO WS-PAYOUT-AMT
           END-IF
           SUBTRACT WS-DEDUCTIBLE FROM WS-PAYOUT-AMT
           IF WS-PAYOUT-AMT < 0
               MOVE ZEROS TO WS-PAYOUT-AMT
           END-IF
           IF WS-PREV-CLAIMS >= 3
               MOVE 0.20 TO WS-COPAY-PCT
           ELSE IF WS-PREV-CLAIMS >= 1
               MOVE 0.10 TO WS-COPAY-PCT
           ELSE
               MOVE 0.00 TO WS-COPAY-PCT
           END-IF
           IF WS-CLAIM-AMOUNT > 50000
               MOVE 'HIGH' TO WS-PRIORITY
           ELSE IF WS-CLAIM-AMOUNT > 10000
               MOVE 'MEDIUM' TO WS-PRIORITY
           ELSE
               MOVE 'LOW' TO WS-PRIORITY
           END-IF
           MOVE 'APPROVED' TO WS-ADJ-STATUS.

       CALCULATE-PAYOUT.
           COMPUTE WS-COPAY-AMT =
               WS-PAYOUT-AMT * WS-COPAY-PCT
           COMPUTE WS-NET-PAYOUT =
               WS-PAYOUT-AMT - WS-COPAY-AMT.

       DISPLAY-RESULT.
           DISPLAY '=== CLAIM RESULT ==='
           DISPLAY 'CLAIM:     ' WS-CLAIM-NUM
           DISPLAY 'POLICY:    ' WS-POLICY-NUM
           DISPLAY 'TYPE:      ' WS-CLAIM-TYPE
           DISPLAY 'AMOUNT:    ' WS-CLAIM-AMOUNT
           DISPLAY 'STATUS:    ' WS-ADJ-STATUS
           IF WS-VALID-CLAIM = 'Y'
               DISPLAY 'DEDUCTIBLE:' WS-DEDUCTIBLE
               DISPLAY 'COPAY:     ' WS-COPAY-AMT
               DISPLAY 'PAYOUT:    ' WS-NET-PAYOUT
               DISPLAY 'PRIORITY:  ' WS-PRIORITY
           ELSE
               DISPLAY 'REASON:    ' WS-ADJ-REASON
           END-IF.
