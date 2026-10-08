       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE-SIMPLE.
      *---------------------------------------------------------------
      * MOVE to multiple targets - customer record population
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT-NAME       PIC X(30)    VALUE 'TREMBLAY, JEAN-PAUL'.
       01  WS-INPUT-CITY       PIC X(20)    VALUE 'MONTREAL'.
       01  WS-INPUT-PROV       PIC X(2)     VALUE 'QC'.
       01  WS-INPUT-POSTAL     PIC X(7)     VALUE 'H2X 1Y4'.
       01  WS-CUSTOMER-REC.
           05  WS-CUST-NAME    PIC X(30)    VALUE SPACES.
           05  WS-CUST-CITY    PIC X(20)    VALUE SPACES.
           05  WS-CUST-PROV    PIC X(2)     VALUE SPACES.
           05  WS-CUST-POSTAL  PIC X(7)     VALUE SPACES.
           05  WS-CUST-STATUS  PIC X        VALUE SPACES.
       01  WS-REPORT-LINE.
           05  WS-RPT-NAME     PIC X(30)    VALUE SPACES.
           05  WS-RPT-CITY     PIC X(20)    VALUE SPACES.
           05  WS-RPT-PROV     PIC X(2)     VALUE SPACES.
       01  WS-ARCHIVE-NAME     PIC X(30)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE WS-INPUT-NAME TO WS-CUST-NAME
           MOVE WS-INPUT-CITY TO WS-CUST-CITY
           MOVE WS-INPUT-PROV TO WS-CUST-PROV
           MOVE WS-INPUT-POSTAL TO WS-CUST-POSTAL
           MOVE 'A' TO WS-CUST-STATUS
           MOVE WS-CUST-NAME TO WS-RPT-NAME
           MOVE WS-CUST-CITY TO WS-RPT-CITY
           MOVE WS-CUST-PROV TO WS-RPT-PROV
           MOVE WS-CUST-NAME TO WS-ARCHIVE-NAME
           DISPLAY 'CUSTOMER: ' WS-CUST-NAME
           DISPLAY 'CITY:     ' WS-CUST-CITY
           DISPLAY 'PROVINCE: ' WS-CUST-PROV
           DISPLAY 'POSTAL:   ' WS-CUST-POSTAL
           DISPLAY 'REPORT:   ' WS-REPORT-LINE
           DISPLAY 'ARCHIVE:  ' WS-ARCHIVE-NAME
           STOP RUN.
