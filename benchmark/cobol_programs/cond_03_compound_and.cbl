       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMPOUND-AND-COND.
      *---------------------------------------------------------------
      * IF with AND conditions - vehicle insurance eligibility
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-DRIVER-ID        PIC X(10)    VALUE 'DRV-045231'.
       01  WS-AGE              PIC 9(3)     VALUE 28.
       01  WS-LICENSE-YEARS    PIC 9(2)     VALUE 6.
       01  WS-ACCIDENTS        PIC 9(2)     VALUE 0.
       01  WS-VIOLATIONS       PIC 9(2)     VALUE 1.
       01  WS-VEHICLE-YEAR     PIC 9(4)     VALUE 2021.
       01  WS-CURRENT-YEAR     PIC 9(4)     VALUE 2024.
       01  WS-VEHICLE-AGE      PIC 9(2)     VALUE ZEROS.
       01  WS-ELIGIBLE         PIC X        VALUE SPACES.
       01  WS-RATE-CLASS       PIC X(12)    VALUE SPACES.
       01  WS-BASE-RATE        PIC 9(5)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-VEHICLE-AGE =
               WS-CURRENT-YEAR - WS-VEHICLE-YEAR
           IF WS-AGE >= 25
               AND WS-LICENSE-YEARS >= 3
               AND WS-ACCIDENTS = 0
               AND WS-VIOLATIONS <= 1
               MOVE 'Y' TO WS-ELIGIBLE
               MOVE 'PREFERRED' TO WS-RATE-CLASS
               MOVE 1200.00 TO WS-BASE-RATE
           END-IF
           IF WS-AGE >= 25
               AND WS-LICENSE-YEARS >= 2
               AND WS-ACCIDENTS <= 1
               AND WS-VIOLATIONS <= 2
               AND WS-ELIGIBLE = SPACES
               MOVE 'Y' TO WS-ELIGIBLE
               MOVE 'STANDARD' TO WS-RATE-CLASS
               MOVE 1800.00 TO WS-BASE-RATE
           END-IF
           IF WS-AGE >= 21
               AND WS-LICENSE-YEARS >= 1
               AND WS-ACCIDENTS <= 2
               AND WS-ELIGIBLE = SPACES
               MOVE 'Y' TO WS-ELIGIBLE
               MOVE 'HIGH-RISK' TO WS-RATE-CLASS
               MOVE 3200.00 TO WS-BASE-RATE
           END-IF
           IF WS-ELIGIBLE = SPACES
               MOVE 'N' TO WS-ELIGIBLE
               MOVE 'DECLINED' TO WS-RATE-CLASS
               MOVE ZEROS TO WS-BASE-RATE
           END-IF
           IF WS-VEHICLE-AGE > 10 AND WS-ELIGIBLE = 'Y'
               COMPUTE WS-BASE-RATE =
                   WS-BASE-RATE * 0.85
           END-IF
           DISPLAY 'DRIVER:    ' WS-DRIVER-ID
           DISPLAY 'ELIGIBLE:  ' WS-ELIGIBLE
           DISPLAY 'CLASS:     ' WS-RATE-CLASS
           DISPLAY 'BASE RATE: ' WS-BASE-RATE
           STOP RUN.
