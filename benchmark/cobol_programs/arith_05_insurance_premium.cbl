       IDENTIFICATION DIVISION.
       PROGRAM-ID. INSURANCE-PREMIUM.
      *---------------------------------------------------------------
      * Insurance premium calculation based on age brackets
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-POLICY-NUM       PIC X(10)    VALUE 'POL-003421'.
       01  WS-AGE              PIC 9(3)     VALUE 42.
       01  WS-SMOKER-FLAG      PIC X        VALUE 'N'.
       01  WS-BASE-PREMIUM     PIC 9(6)V99  VALUE ZEROS.
       01  WS-SMOKER-SURCHARGE PIC 9(6)V99  VALUE ZEROS.
       01  WS-FINAL-PREMIUM    PIC 9(6)V99  VALUE ZEROS.
       01  WS-RISK-CATEGORY    PIC X(10)    VALUE SPACES.
       01  WS-SMOKER-RATE      PIC 9V99     VALUE 1.35.

       PROCEDURE DIVISION.
       MAIN-PARA.
           EVALUATE TRUE
               WHEN WS-AGE < 25
                   MOVE 1200.00 TO WS-BASE-PREMIUM
                   MOVE 'LOW RISK' TO WS-RISK-CATEGORY
               WHEN WS-AGE < 35
                   MOVE 1800.00 TO WS-BASE-PREMIUM
                   MOVE 'MODERATE' TO WS-RISK-CATEGORY
               WHEN WS-AGE < 45
                   MOVE 2700.00 TO WS-BASE-PREMIUM
                   MOVE 'STANDARD' TO WS-RISK-CATEGORY
               WHEN WS-AGE < 55
                   MOVE 4200.00 TO WS-BASE-PREMIUM
                   MOVE 'ELEVATED' TO WS-RISK-CATEGORY
               WHEN WS-AGE < 65
                   MOVE 6500.00 TO WS-BASE-PREMIUM
                   MOVE 'HIGH' TO WS-RISK-CATEGORY
               WHEN OTHER
                   MOVE 9800.00 TO WS-BASE-PREMIUM
                   MOVE 'SENIOR' TO WS-RISK-CATEGORY
           END-EVALUATE
           IF WS-SMOKER-FLAG = 'Y'
               COMPUTE WS-SMOKER-SURCHARGE =
                   WS-BASE-PREMIUM * (WS-SMOKER-RATE - 1)
           ELSE
               MOVE ZEROS TO WS-SMOKER-SURCHARGE
           END-IF
           COMPUTE WS-FINAL-PREMIUM =
               WS-BASE-PREMIUM + WS-SMOKER-SURCHARGE
           DISPLAY 'POLICY:    ' WS-POLICY-NUM
           DISPLAY 'AGE:       ' WS-AGE
           DISPLAY 'RISK:      ' WS-RISK-CATEGORY
           DISPLAY 'PREMIUM:   ' WS-FINAL-PREMIUM
           STOP RUN.
