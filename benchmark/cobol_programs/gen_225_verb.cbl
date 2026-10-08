       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-VERB-225.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-A                 PIC 9(5)V99  VALUE 6888.47.
       01  WS-B                 PIC 9(5)V99  VALUE 6267.57.
       01  WS-C                 PIC 9(5)V99  VALUE 6185.48.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           ADD WS-A WS-B GIVING WS-RESULT
           ADD WS-C TO WS-RESULT
           STOP RUN.
