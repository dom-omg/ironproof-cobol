       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-049.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)  VALUE 30317.
       01  WS-V2                PIC 9(3)  VALUE 133.
       01  WS-V3                PIC 9(3)  VALUE 748.
       01  WS-V4                PIC 9(3)  VALUE 207.
       01  WS-V5                PIC 9(3)  VALUE 333.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 - WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT / WS-V5
           STOP RUN.
