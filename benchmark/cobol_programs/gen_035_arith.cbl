       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-035.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(3)  VALUE 506.
       01  WS-V2                PIC 9(3)  VALUE 651.
       01  WS-V3                PIC 9(5)V99  VALUE 3920.35.
       01  WS-V4                PIC 9(5)  VALUE 57754.
       01  WS-V5                PIC 9(3)  VALUE 89.
       01  WS-V6                PIC 9(5)  VALUE 93625.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 * WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT * WS-V6
           STOP RUN.
