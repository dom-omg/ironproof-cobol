       IDENTIFICATION DIVISION.
       PROGRAM-ID. BOUNDARY-CHECK.
      *---------------------------------------------------------------
      * Boundary value checks with <=, <, >=, > operators
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-SENSOR-ID        PIC X(8)     VALUE 'SNS-0042'.
       01  WS-TEMPERATURE      PIC S9(3)V99 VALUE 98.75.
       01  WS-PRESSURE         PIC 9(4)V99  VALUE 1013.25.
       01  WS-HUMIDITY         PIC 9(3)V9   VALUE 65.5.
       01  WS-TEMP-STATUS      PIC X(12)    VALUE SPACES.
       01  WS-PRESS-STATUS     PIC X(12)    VALUE SPACES.
       01  WS-HUMID-STATUS     PIC X(12)    VALUE SPACES.
       01  WS-ALARM-LEVEL      PIC 9        VALUE ZEROS.
       01  WS-ALARM-COUNT      PIC 9(2)     VALUE ZEROS.
       01  WS-OVERALL-STATUS   PIC X(10)    VALUE SPACES.

       PROCEDURE DIVISION.
       MAIN-PARA.
           MOVE ZEROS TO WS-ALARM-COUNT
           IF WS-TEMPERATURE > 100.00
               MOVE 'CRITICAL HI' TO WS-TEMP-STATUS
               ADD 1 TO WS-ALARM-COUNT
           ELSE IF WS-TEMPERATURE >= 90.00
               MOVE 'WARNING HI' TO WS-TEMP-STATUS
           ELSE IF WS-TEMPERATURE > 60.00
               MOVE 'NORMAL' TO WS-TEMP-STATUS
           ELSE IF WS-TEMPERATURE >= 40.00
               MOVE 'WARNING LO' TO WS-TEMP-STATUS
           ELSE
               MOVE 'CRITICAL LO' TO WS-TEMP-STATUS
               ADD 1 TO WS-ALARM-COUNT
           END-IF
           IF WS-PRESSURE > 1050.00
               MOVE 'HIGH' TO WS-PRESS-STATUS
               ADD 1 TO WS-ALARM-COUNT
           ELSE IF WS-PRESSURE >= 980.00
               MOVE 'NORMAL' TO WS-PRESS-STATUS
           ELSE IF WS-PRESSURE < 950.00
               MOVE 'CRITICAL LO' TO WS-PRESS-STATUS
               ADD 1 TO WS-ALARM-COUNT
           ELSE
               MOVE 'LOW' TO WS-PRESS-STATUS
           END-IF
           IF WS-HUMIDITY >= 80.0
               MOVE 'HIGH' TO WS-HUMID-STATUS
               ADD 1 TO WS-ALARM-COUNT
           ELSE IF WS-HUMIDITY > 30.0
               MOVE 'NORMAL' TO WS-HUMID-STATUS
           ELSE IF WS-HUMIDITY <= 20.0
               MOVE 'CRITICAL LO' TO WS-HUMID-STATUS
               ADD 1 TO WS-ALARM-COUNT
           ELSE
               MOVE 'LOW' TO WS-HUMID-STATUS
           END-IF
           IF WS-ALARM-COUNT >= 3
               MOVE 'EMERGENCY' TO WS-OVERALL-STATUS
               MOVE 3 TO WS-ALARM-LEVEL
           ELSE IF WS-ALARM-COUNT >= 1
               MOVE 'ALERT' TO WS-OVERALL-STATUS
               MOVE 2 TO WS-ALARM-LEVEL
           ELSE
               MOVE 'NORMAL' TO WS-OVERALL-STATUS
               MOVE 0 TO WS-ALARM-LEVEL
           END-IF
           DISPLAY 'SENSOR:   ' WS-SENSOR-ID
           DISPLAY 'TEMP:     ' WS-TEMP-STATUS
           DISPLAY 'PRESSURE: ' WS-PRESS-STATUS
           DISPLAY 'HUMIDITY: ' WS-HUMID-STATUS
           DISPLAY 'ALARMS:   ' WS-ALARM-COUNT
           DISPLAY 'STATUS:   ' WS-OVERALL-STATUS
           STOP RUN.
