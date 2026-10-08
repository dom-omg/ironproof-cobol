       IDENTIFICATION DIVISION.
       PROGRAM-ID. MOVE-REFORMAT.
      *---------------------------------------------------------------
      * Data reformatting with MOVE - date and name formatting
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUT-DATE       PIC 9(8)     VALUE 20240315.
       01  WS-DATE-PARTS.
           05  WS-IN-YEAR      PIC 9(4)     VALUE ZEROS.
           05  WS-IN-MONTH     PIC 9(2)     VALUE ZEROS.
           05  WS-IN-DAY       PIC 9(2)     VALUE ZEROS.
       01  WS-FORMATTED-DATE   PIC X(10)    VALUE SPACES.
       01  WS-ISO-DATE         PIC X(10)    VALUE SPACES.
       01  WS-MONTH-NAME       PIC X(9)     VALUE SPACES.
       01  WS-FIRST-NAME       PIC X(15)    VALUE 'JEAN-PAUL'.
       01  WS-LAST-NAME        PIC X(20)    VALUE 'TREMBLAY'.
       01  WS-FULL-NAME        PIC X(36)    VALUE SPACES.
       01  WS-SORT-NAME        PIC X(36)    VALUE SPACES.
       01  WS-ACCT-RAW         PIC 9(12)    VALUE 100045678901.
       01  WS-ACCT-FORMATTED   PIC X(14)    VALUE SPACES.
       01  WS-ACCT-PART1       PIC 9(4)     VALUE ZEROS.
       01  WS-ACCT-PART2       PIC 9(4)     VALUE ZEROS.
       01  WS-ACCT-PART3       PIC 9(4)     VALUE ZEROS.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE WS-INPUT-DATE TO WS-DATE-PARTS
           EVALUATE WS-IN-MONTH
               WHEN 01  MOVE 'JANUARY' TO WS-MONTH-NAME
               WHEN 02  MOVE 'FEBRUARY' TO WS-MONTH-NAME
               WHEN 03  MOVE 'MARCH' TO WS-MONTH-NAME
               WHEN 04  MOVE 'APRIL' TO WS-MONTH-NAME
               WHEN 05  MOVE 'MAY' TO WS-MONTH-NAME
               WHEN 06  MOVE 'JUNE' TO WS-MONTH-NAME
               WHEN 07  MOVE 'JULY' TO WS-MONTH-NAME
               WHEN 08  MOVE 'AUGUST' TO WS-MONTH-NAME
               WHEN 09  MOVE 'SEPTEMBER' TO WS-MONTH-NAME
               WHEN 10  MOVE 'OCTOBER' TO WS-MONTH-NAME
               WHEN 11  MOVE 'NOVEMBER' TO WS-MONTH-NAME
               WHEN 12  MOVE 'DECEMBER' TO WS-MONTH-NAME
               WHEN OTHER MOVE 'UNKNOWN' TO WS-MONTH-NAME
           END-EVALUATE
           MOVE SPACES TO WS-FULL-NAME
           MOVE SPACES TO WS-SORT-NAME
           MOVE WS-FIRST-NAME TO WS-FULL-NAME(1:15)
           MOVE WS-LAST-NAME TO WS-FULL-NAME(17:20)
           MOVE WS-LAST-NAME TO WS-SORT-NAME(1:20)
           MOVE WS-FIRST-NAME TO WS-SORT-NAME(22:15)
           DISPLAY 'INPUT DATE:  ' WS-INPUT-DATE
           DISPLAY 'MONTH:       ' WS-MONTH-NAME
           DISPLAY 'FULL NAME:   ' WS-FULL-NAME
           DISPLAY 'SORT NAME:   ' WS-SORT-NAME
           STOP RUN.
