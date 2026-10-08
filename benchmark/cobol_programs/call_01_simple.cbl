       IDENTIFICATION DIVISION.
       PROGRAM-ID. CALL-SIMPLE.
      *---------------------------------------------------------------
      * CALL with USING - validate and process customer data
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-CUSTOMER-ID      PIC X(10)    VALUE 'CUST001234'.
       01  WS-CUSTOMER-NAME    PIC X(30)    VALUE 'LAVOIE, MARIE-CLAIRE'.
       01  WS-CUSTOMER-DATA.
           05  WS-CD-ID        PIC X(10)    VALUE SPACES.
           05  WS-CD-NAME      PIC X(30)    VALUE SPACES.
           05  WS-CD-TYPE      PIC X        VALUE SPACES.
           05  WS-CD-BALANCE   PIC S9(9)V99 VALUE ZEROS.
           05  WS-CD-STATUS    PIC X(2)     VALUE SPACES.
       01  WS-VALIDATION-RESULT.
           05  WS-VR-VALID     PIC X        VALUE SPACES.
           05  WS-VR-MSG       PIC X(40)    VALUE SPACES.
           05  WS-VR-CODE      PIC 9(4)     VALUE ZEROS.
       01  WS-CALC-REQUEST.
           05  WS-CR-BALANCE   PIC S9(9)V99 VALUE ZEROS.
           05  WS-CR-RATE      PIC 9V9999   VALUE 0.0350.
           05  WS-CR-DAYS      PIC 9(3)     VALUE 30.
           05  WS-CR-INTEREST  PIC 9(7)V99  VALUE ZEROS.
       01  WS-RETURN-CODE      PIC 9(4)     VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE WS-CUSTOMER-ID TO WS-CD-ID
           MOVE WS-CUSTOMER-NAME TO WS-CD-NAME
           MOVE 'P' TO WS-CD-TYPE
           MOVE 15000.00 TO WS-CD-BALANCE
           CALL 'CUSTVAL' USING WS-CUSTOMER-DATA
                                WS-VALIDATION-RESULT
           IF WS-VR-VALID = 'Y'
               DISPLAY 'VALIDATION: PASSED'
               MOVE WS-CD-BALANCE TO WS-CR-BALANCE
               CALL 'INTCALC' USING WS-CALC-REQUEST
               DISPLAY 'INTEREST: ' WS-CR-INTEREST
           ELSE
               DISPLAY 'VALIDATION: FAILED'
               DISPLAY 'MESSAGE: ' WS-VR-MSG
               DISPLAY 'CODE:    ' WS-VR-CODE
           END-IF
           CALL 'AUDITLOG' USING WS-CUSTOMER-DATA
                                 WS-RETURN-CODE
           IF WS-RETURN-CODE = 0
               DISPLAY 'AUDIT LOG: RECORDED'
           ELSE
               DISPLAY 'AUDIT LOG: FAILED RC=' WS-RETURN-CODE
           END-IF
           DISPLAY 'CUSTOMER:  ' WS-CD-ID
           DISPLAY 'NAME:      ' WS-CD-NAME
           DISPLAY 'BALANCE:   ' WS-CD-BALANCE
           STOP RUN.
