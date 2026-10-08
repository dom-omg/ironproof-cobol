       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-045.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)V99  VALUE 8818.99.
       01  WS-V2                PIC 9(5)  VALUE 63472.
       01  WS-V3                PIC 9(5)  VALUE 61031.
       01  WS-V4                PIC 9(5)  VALUE 57191.
       01  WS-V5                PIC 9(3)  VALUE 855.
       01  WS-V6                PIC 9(5)  VALUE 95917.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 + WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT * WS-V6
           STOP RUN.
