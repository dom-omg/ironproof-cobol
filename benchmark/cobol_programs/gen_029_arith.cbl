       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-029.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)V99  VALUE 5140.55.
       01  WS-V2                PIC 9(5)V99  VALUE 9933.65.
       01  WS-V3                PIC 9(5)  VALUE 15257.
       01  WS-V4                PIC 9(3)  VALUE 404.
       01  WS-V5                PIC 9(3)  VALUE 931.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 / WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT + WS-V5
           STOP RUN.
