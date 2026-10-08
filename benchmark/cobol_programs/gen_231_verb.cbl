       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-VERB-231.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-A                 PIC 9(5)V99  VALUE 7315.76.
       01  WS-B                 PIC 9(5)V99  VALUE 798.31.
       01  WS-C                 PIC 9(5)V99  VALUE 725.51.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           DIVIDE WS-A BY WS-B GIVING WS-RESULT
           COMPUTE WS-RESULT2 = WS-RESULT + WS-C
           STOP RUN.
