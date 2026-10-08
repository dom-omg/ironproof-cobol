       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-044.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)  VALUE 66417.
       01  WS-V2                PIC 9(3)  VALUE 673.
       01  WS-V3                PIC 9(5)  VALUE 44825.
       01  WS-V4                PIC 9(3)  VALUE 22.
       01  WS-V5                PIC 9(5)V99  VALUE 6883.62.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 / WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT - WS-V5
           STOP RUN.
