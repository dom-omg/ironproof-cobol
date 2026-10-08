       IDENTIFICATION DIVISION.
       PROGRAM-ID. GEN-ARITH-028.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-V1                PIC 9(5)V99  VALUE 6529.42.
       01  WS-V2                PIC 9(5)V99  VALUE 4565.08.
       01  WS-V3                PIC 9(5)V99  VALUE 4574.44.
       01  WS-V4                PIC 9(5)  VALUE 84180.
       01  WS-V5                PIC 9(5)V99  VALUE 8347.51.
       01  WS-RESULT            PIC 9(8)V99  VALUE ZEROS.
       01  WS-RESULT2           PIC 9(8)V99  VALUE ZEROS.
       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-RESULT = WS-V1 * WS-V2
           COMPUTE WS-RESULT2 = WS-RESULT - WS-V5
           STOP RUN.
