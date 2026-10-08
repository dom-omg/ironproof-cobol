       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-VERB-293.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-A                 PIC 9(5)V99  VALUE 1792.98.
       01  WS-B                 PIC 9(5)V99  VALUE 4068.84.
       01  WS-C                 PIC 9(5)V99  VALUE 5817.21.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           ADD WS-A WS-B GIVING WS-RESULT
           ADD WS-C TO WS-RESULT
           STOP RUN.
