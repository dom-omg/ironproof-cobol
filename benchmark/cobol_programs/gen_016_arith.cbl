       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-016.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)V99  VALUE 1236.56.
       01  WS-V2                PIC 9(3)  VALUE 837.
       01  WS-V3                PIC 9(5)V99  VALUE 9017.12.
       01  WS-V4                PIC 9(3)  VALUE 61.
       01  WS-V5                PIC 9(3)  VALUE 677.
       01  WS-V6                PIC 9(5)V99  VALUE 8857.01.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 / WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT / WS-V6
           STOP RUN.
