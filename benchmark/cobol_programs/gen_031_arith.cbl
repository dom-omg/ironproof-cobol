       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-031.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)  VALUE 49795.
       01  WS-V2                PIC 9(5)V99  VALUE 2852.78.
       01  WS-V3                PIC 9(5)V99  VALUE 9325.38.
       01  WS-V4                PIC 9(3)  VALUE 425.
       01  WS-V5                PIC 9(5)  VALUE 71919.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 - WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT / WS-V5
           STOP RUN.
