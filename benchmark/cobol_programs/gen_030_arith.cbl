       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-030.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(3)  VALUE 952.
       01  WS-V2                PIC 9(3)  VALUE 348.
       01  WS-V3                PIC 9(5)V99  VALUE 5144.84.
       01  WS-V4                PIC 9(5)  VALUE 16434.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 * WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT / WS-V4
           STOP RUN.
