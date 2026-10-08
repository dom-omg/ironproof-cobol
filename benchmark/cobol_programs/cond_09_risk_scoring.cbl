       IDENTIFICATION DIVISION.
       PROGRAM-ID. RISK-SCORING.
      *---------------------------------------------------------------
      * Risk score calculation with weighted factors
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-PORTFOLIO-ID     PIC X(10)    VALUE 'PRT-002341'.
       01  WS-MARKET-VOL       PIC 9(3)     VALUE 28.
       01  WS-CREDIT-EXP       PIC 9V99     VALUE 0.45.
       01  WS-LIQUIDITY-RATIO  PIC 9V99     VALUE 0.72.
       01  WS-DURATION-YEARS   PIC 9(2)     VALUE 7.
       01  WS-CONCENTRATION    PIC 9V99     VALUE 0.35.
       01  WS-WT-MARKET        PIC 9V99     VALUE 0.25.
       01  WS-WT-CREDIT        PIC 9V99     VALUE 0.20.
       01  WS-WT-LIQUIDITY     PIC 9V99     VALUE 0.20.
       01  WS-WT-DURATION      PIC 9V99     VALUE 0.15.
       01  WS-WT-CONCENTR      PIC 9V99     VALUE 0.20.
       01  WS-SCORE-MARKET     PIC 9(3)V99  VALUE ZEROS.
       01  WS-SCORE-CREDIT     PIC 9(3)V99  VALUE ZEROS.
       01  WS-SCORE-LIQUID     PIC 9(3)V99  VALUE ZEROS.
       01  WS-SCORE-DURATION   PIC 9(3)V99  VALUE ZEROS.
       01  WS-SCORE-CONCENTR   PIC 9(3)V99  VALUE ZEROS.
       01  WS-TOTAL-RISK       PIC 9(3)V99  VALUE ZEROS.
       01  WS-RISK-CATEGORY    PIC X(12)    VALUE SPACES.
       01  WS-ACTION-REQUIRED  PIC X(20)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           IF WS-MARKET-VOL > 40
               MOVE 100 TO WS-SCORE-MARKET
           ELSE IF WS-MARKET-VOL > 25
               COMPUTE WS-SCORE-MARKET =
                   (WS-MARKET-VOL - 25) * 100 / 15
           ELSE
               COMPUTE WS-SCORE-MARKET =
                   WS-MARKET-VOL * 2
           END-IF
           COMPUTE WS-SCORE-CREDIT =
               WS-CREDIT-EXP * 100
           IF WS-LIQUIDITY-RATIO < 0.20
               MOVE 100 TO WS-SCORE-LIQUID
           ELSE IF WS-LIQUIDITY-RATIO < 0.50
               COMPUTE WS-SCORE-LIQUID =
                   (0.50 - WS-LIQUIDITY-RATIO) * 200
           ELSE
               MOVE 10 TO WS-SCORE-LIQUID
           END-IF
           IF WS-DURATION-YEARS > 10
               MOVE 80 TO WS-SCORE-DURATION
           ELSE
               COMPUTE WS-SCORE-DURATION =
                   WS-DURATION-YEARS * 8
           END-IF
           COMPUTE WS-SCORE-CONCENTR =
               WS-CONCENTRATION * 100
           COMPUTE WS-TOTAL-RISK =
               WS-SCORE-MARKET * WS-WT-MARKET
               + WS-SCORE-CREDIT * WS-WT-CREDIT
               + WS-SCORE-LIQUID * WS-WT-LIQUIDITY
               + WS-SCORE-DURATION * WS-WT-DURATION
               + WS-SCORE-CONCENTR * WS-WT-CONCENTR
           EVALUATE TRUE
               WHEN WS-TOTAL-RISK >= 75
                   MOVE 'CRITICAL' TO WS-RISK-CATEGORY
                   MOVE 'IMMEDIATE REBALANCE' TO WS-ACTION-REQUIRED
               WHEN WS-TOTAL-RISK >= 50
                   MOVE 'HIGH' TO WS-RISK-CATEGORY
                   MOVE 'REVIEW REQUIRED' TO WS-ACTION-REQUIRED
               WHEN WS-TOTAL-RISK >= 25
                   MOVE 'MODERATE' TO WS-RISK-CATEGORY
                   MOVE 'MONITOR CLOSELY' TO WS-ACTION-REQUIRED
               WHEN OTHER
                   MOVE 'LOW' TO WS-RISK-CATEGORY
                   MOVE 'ROUTINE REVIEW' TO WS-ACTION-REQUIRED
           END-EVALUATE
           DISPLAY 'PORTFOLIO: ' WS-PORTFOLIO-ID
           DISPLAY 'RISK SCORE:' WS-TOTAL-RISK
           DISPLAY 'CATEGORY:  ' WS-RISK-CATEGORY
           DISPLAY 'ACTION:    ' WS-ACTION-REQUIRED
           STOP RUN.
