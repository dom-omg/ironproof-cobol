       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-046.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)V99  VALUE 5512.03.
       01  WS-V2                PIC 9(3)  VALUE 516.
       01  WS-V3                PIC 9(5)  VALUE 42700.
       01  WS-V4                PIC 9(5)  VALUE 23934.
       01  WS-V5                PIC 9(5)  VALUE 64004.
       01  WS-V6                PIC 9(3)  VALUE 227.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 * WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT * WS-V6
           STOP RUN.
