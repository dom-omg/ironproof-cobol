       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-VERB-221.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-A                 PIC 9(5)V99  VALUE 946.71.
       01  WS-B                 PIC 9(5)V99  VALUE 7576.86.
       01  WS-C                 PIC 9(5)V99  VALUE 5050.92.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           ADD WS-A WS-B GIVING WS-RESULT
           ADD WS-C TO WS-RESULT
           STOP RUN.
