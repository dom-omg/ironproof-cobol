       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE-CHAIN.
      *---------------------------------------------------------------
      * Chain of MOVE operations - data transformation pipeline
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-RAW-RECORD       PIC X(50)    VALUE SPACES.
       01  WS-STAGE-1.
           05  WS-S1-CODE      PIC X(5)     VALUE SPACES.
           05  WS-S1-AMOUNT    PIC 9(7)V99  VALUE ZEROS.
           05  WS-S1-DATE      PIC 9(8)     VALUE ZEROS.
           05  WS-S1-FLAG      PIC X        VALUE SPACES.
       01  WS-STAGE-2.
           05  WS-S2-CODE      PIC X(5)     VALUE SPACES.
           05  WS-S2-AMOUNT    PIC 9(7)V99  VALUE ZEROS.
           05  WS-S2-DATE      PIC 9(8)     VALUE ZEROS.
           05  WS-S2-STATUS    PIC X(3)     VALUE SPACES.
       01  WS-FINAL-REC.
           05  WS-FIN-CODE     PIC X(5)     VALUE SPACES.
           05  WS-FIN-AMOUNT   PIC 9(7)V99  VALUE ZEROS.
           05  WS-FIN-DATE     PIC 9(8)     VALUE ZEROS.
           05  WS-FIN-STATUS   PIC X(3)     VALUE SPACES.
           05  WS-FIN-PROC     PIC X        VALUE SPACES.
       01  WS-TEMP-CODE        PIC X(5)     VALUE SPACES.
       01  WS-TEMP-AMT         PIC 9(7)V99  VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE 'TX001' TO WS-S1-CODE
           MOVE 15750.50 TO WS-S1-AMOUNT
           MOVE 20240315 TO WS-S1-DATE
           MOVE 'A' TO WS-S1-FLAG
           MOVE WS-S1-CODE TO WS-S2-CODE
           MOVE WS-S1-AMOUNT TO WS-S2-AMOUNT
           MOVE WS-S1-DATE TO WS-S2-DATE
           IF WS-S1-FLAG = 'A'
               MOVE 'ACT' TO WS-S2-STATUS
           ELSE
               MOVE 'INA' TO WS-S2-STATUS
           END-IF
           MOVE WS-S2-CODE TO WS-TEMP-CODE
           MOVE WS-S2-AMOUNT TO WS-TEMP-AMT
           MOVE WS-TEMP-CODE TO WS-FIN-CODE
           MOVE WS-TEMP-AMT TO WS-FIN-AMOUNT
           MOVE WS-S2-DATE TO WS-FIN-DATE
           MOVE WS-S2-STATUS TO WS-FIN-STATUS
           MOVE 'Y' TO WS-FIN-PROC
           DISPLAY 'STAGE 1: ' WS-STAGE-1
           DISPLAY 'STAGE 2: ' WS-STAGE-2
           DISPLAY 'FINAL:   ' WS-FINAL-REC
           STOP RUN.
