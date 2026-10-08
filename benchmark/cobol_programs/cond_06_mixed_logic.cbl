       IDENTIFICATION DIVISION.
       PROGRAM-ID. MIXED-LOGIC-DEMO.
      *---------------------------------------------------------------
      * Mix of IF, EVALUATE, nested - employee benefits eligibility
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-EMP-ID           PIC X(8)     VALUE 'EMP00456'.
       01  WS-EMP-TYPE         PIC X        VALUE 'F'.
       01  WS-TENURE-MONTHS    PIC 9(3)     VALUE 36.
       01  WS-SALARY           PIC 9(7)V99  VALUE 55000.00.
       01  WS-DEPARTMENT       PIC X(3)     VALUE 'ENG'.
       01  WS-HEALTH-PLAN      PIC X(10)    VALUE SPACES.
       01  WS-DENTAL-ELIG      PIC X        VALUE 'N'.
       01  WS-VISION-ELIG      PIC X        VALUE 'N'.
       01  WS-RRSP-MATCH-PCT   PIC 9V99     VALUE ZEROS.
       01  WS-VACATION-DAYS    PIC 9(2)     VALUE ZEROS.
       01  WS-BENEFITS-COST    PIC 9(6)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-EMP-TYPE = 'F'
               EVALUATE TRUE
                   WHEN WS-TENURE-MONTHS >= 60
                       MOVE 'PREMIUM' TO WS-HEALTH-PLAN
                       MOVE 'Y' TO WS-DENTAL-ELIG
                       MOVE 'Y' TO WS-VISION-ELIG
                       MOVE 0.06 TO WS-RRSP-MATCH-PCT
                   WHEN WS-TENURE-MONTHS >= 24
                       MOVE 'STANDARD' TO WS-HEALTH-PLAN
                       MOVE 'Y' TO WS-DENTAL-ELIG
                       MOVE 'N' TO WS-VISION-ELIG
                       MOVE 0.04 TO WS-RRSP-MATCH-PCT
                   WHEN WS-TENURE-MONTHS >= 3
                       MOVE 'BASIC' TO WS-HEALTH-PLAN
                       MOVE 'N' TO WS-DENTAL-ELIG
                       MOVE 'N' TO WS-VISION-ELIG
                       MOVE 0.02 TO WS-RRSP-MATCH-PCT
                   WHEN OTHER
                       MOVE 'NONE' TO WS-HEALTH-PLAN
                       MOVE 0.00 TO WS-RRSP-MATCH-PCT
               END-EVALUATE
               EVALUATE TRUE
                   WHEN WS-TENURE-MONTHS >= 120
                       MOVE 25 TO WS-VACATION-DAYS
                   WHEN WS-TENURE-MONTHS >= 60
                       MOVE 20 TO WS-VACATION-DAYS
                   WHEN OTHER
                       MOVE 15 TO WS-VACATION-DAYS
               END-EVALUATE
           ELSE
               MOVE 'CONTRACTOR' TO WS-HEALTH-PLAN
               MOVE 'N' TO WS-DENTAL-ELIG
               MOVE 'N' TO WS-VISION-ELIG
               MOVE 0.00 TO WS-RRSP-MATCH-PCT
               MOVE 0 TO WS-VACATION-DAYS
           END-IF
           IF WS-DEPARTMENT = 'ENG' OR WS-DEPARTMENT = 'MGT'
               ADD 2 TO WS-VACATION-DAYS
           END-IF
           COMPUTE WS-BENEFITS-COST =
               WS-SALARY * WS-RRSP-MATCH-PCT
           DISPLAY 'EMPLOYEE:   ' WS-EMP-ID
           DISPLAY 'HEALTH:     ' WS-HEALTH-PLAN
           DISPLAY 'DENTAL:     ' WS-DENTAL-ELIG
           DISPLAY 'VISION:     ' WS-VISION-ELIG
           DISPLAY 'RRSP MATCH: ' WS-RRSP-MATCH-PCT
           DISPLAY 'VACATION:   ' WS-VACATION-DAYS ' DAYS'
           STOP RUN.
