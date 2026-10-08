       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-041.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)V99  VALUE 1125.99.
       01  WS-V2                PIC 9(5)  VALUE 85526.
       01  WS-V3                PIC 9(5)  VALUE 5376.
       01  WS-V4                PIC 9(5)V99  VALUE 509.31.
       01  WS-V5                PIC 9(3)  VALUE 214.
       01  WS-V6                PIC 9(5)V99  VALUE 334.79.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 / WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT + WS-V6
           STOP RUN.
