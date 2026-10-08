       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-002.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)V99  VALUE 9864.03.
       01  WS-V2                PIC 9(5)V99  VALUE 9196.25.
       01  WS-V3                PIC 9(5)  VALUE 93950.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 * WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT + WS-V3
           STOP RUN.
