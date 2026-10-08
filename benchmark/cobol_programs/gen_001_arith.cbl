       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-001.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)V99  VALUE 4013.28.
       01  WS-V2                PIC 9(5)  VALUE 18389.
       01  WS-V3                PIC 9(3)  VALUE 764.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 + WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT + WS-V3
           STOP RUN.
