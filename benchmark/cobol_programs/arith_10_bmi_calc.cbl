       IDENTIFICATION DIVISION.
       PROGRAM-ID. BMI-CALCULATOR.
      *---------------------------------------------------------------
      * BMI computation and health category assignment
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PATIENT-ID       PIC X(10)    VALUE 'PAT-008734'.
       01  WS-WEIGHT-KG        PIC 9(3)V9   VALUE 82.5.
       01  WS-HEIGHT-CM        PIC 9(3)     VALUE 175.
       01  WS-HEIGHT-M         PIC 9V99     VALUE ZEROS.
       01  WS-HEIGHT-SQ        PIC 9V9999   VALUE ZEROS.
       01  WS-BMI              PIC 9(2)V99  VALUE ZEROS.
       01  WS-CATEGORY         PIC X(20)    VALUE SPACES.
       01  WS-RISK-LEVEL       PIC X(10)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-HEIGHT-M = WS-HEIGHT-CM / 100
           COMPUTE WS-HEIGHT-SQ = WS-HEIGHT-M * WS-HEIGHT-M
           IF WS-HEIGHT-SQ > 0
               COMPUTE WS-BMI = WS-WEIGHT-KG / WS-HEIGHT-SQ
           END-IF
           EVALUATE TRUE
               WHEN WS-BMI < 18.50
                   MOVE 'UNDERWEIGHT' TO WS-CATEGORY
                   MOVE 'MODERATE' TO WS-RISK-LEVEL
               WHEN WS-BMI < 25.00
                   MOVE 'NORMAL WEIGHT' TO WS-CATEGORY
                   MOVE 'LOW' TO WS-RISK-LEVEL
               WHEN WS-BMI < 30.00
                   MOVE 'OVERWEIGHT' TO WS-CATEGORY
                   MOVE 'INCREASED' TO WS-RISK-LEVEL
               WHEN WS-BMI < 35.00
                   MOVE 'OBESE CLASS I' TO WS-CATEGORY
                   MOVE 'HIGH' TO WS-RISK-LEVEL
               WHEN WS-BMI < 40.00
                   MOVE 'OBESE CLASS II' TO WS-CATEGORY
                   MOVE 'VERY HIGH' TO WS-RISK-LEVEL
               WHEN OTHER
                   MOVE 'OBESE CLASS III' TO WS-CATEGORY
                   MOVE 'EXTREME' TO WS-RISK-LEVEL
           END-EVALUATE
           DISPLAY 'PATIENT: ' WS-PATIENT-ID
           DISPLAY 'BMI:     ' WS-BMI
           DISPLAY 'CATEGORY:' WS-CATEGORY
           DISPLAY 'RISK:    ' WS-RISK-LEVEL
           STOP RUN.
