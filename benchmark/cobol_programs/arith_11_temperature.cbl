       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEMPERATURE-CONVERT.
      *---------------------------------------------------------------
      * Celsius/Fahrenheit conversion with weather ranges
      *---------------------------------------------------------------
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TEMP-CELSIUS     PIC S9(3)V99 VALUE 22.50.
       01  WS-TEMP-FAHRENHEIT  PIC S9(3)V99 VALUE ZEROS.
       01  WS-TEMP-KELVIN      PIC 9(3)V99  VALUE ZEROS.
       01  WS-WEATHER-DESC     PIC X(15)    VALUE SPACES.
       01  WS-COMFORT-LEVEL    PIC X(12)    VALUE SPACES.
       01  WS-ALERT-FLAG       PIC X        VALUE 'N'.

       PROCEDURE DIVISION.
       MAIN-PARA.
           COMPUTE WS-TEMP-FAHRENHEIT =
               (WS-TEMP-CELSIUS * 9 / 5) + 32
           COMPUTE WS-TEMP-KELVIN =
               WS-TEMP-CELSIUS + 273.15
           EVALUATE TRUE
               WHEN WS-TEMP-CELSIUS < -30
                   MOVE 'EXTREME COLD' TO WS-WEATHER-DESC
                   MOVE 'DANGEROUS' TO WS-COMFORT-LEVEL
                   MOVE 'Y' TO WS-ALERT-FLAG
               WHEN WS-TEMP-CELSIUS < -10
                   MOVE 'VERY COLD' TO WS-WEATHER-DESC
                   MOVE 'HARSH' TO WS-COMFORT-LEVEL
                   MOVE 'Y' TO WS-ALERT-FLAG
               WHEN WS-TEMP-CELSIUS < 0
                   MOVE 'COLD' TO WS-WEATHER-DESC
                   MOVE 'UNCOMFORT' TO WS-COMFORT-LEVEL
                   MOVE 'N' TO WS-ALERT-FLAG
               WHEN WS-TEMP-CELSIUS < 15
                   MOVE 'COOL' TO WS-WEATHER-DESC
                   MOVE 'MILD' TO WS-COMFORT-LEVEL
                   MOVE 'N' TO WS-ALERT-FLAG
               WHEN WS-TEMP-CELSIUS < 25
                   MOVE 'WARM' TO WS-WEATHER-DESC
                   MOVE 'COMFORTABLE' TO WS-COMFORT-LEVEL
                   MOVE 'N' TO WS-ALERT-FLAG
               WHEN WS-TEMP-CELSIUS < 35
                   MOVE 'HOT' TO WS-WEATHER-DESC
                   MOVE 'WARM' TO WS-COMFORT-LEVEL
                   MOVE 'N' TO WS-ALERT-FLAG
               WHEN OTHER
                   MOVE 'EXTREME HEAT' TO WS-WEATHER-DESC
                   MOVE 'DANGEROUS' TO WS-COMFORT-LEVEL
                   MOVE 'Y' TO WS-ALERT-FLAG
           END-EVALUATE
           DISPLAY 'CELSIUS:    ' WS-TEMP-CELSIUS
           DISPLAY 'FAHRENHEIT: ' WS-TEMP-FAHRENHEIT
           DISPLAY 'KELVIN:     ' WS-TEMP-KELVIN
           DISPLAY 'WEATHER:    ' WS-WEATHER-DESC
           DISPLAY 'COMFORT:    ' WS-COMFORT-LEVEL
           DISPLAY 'ALERT:      ' WS-ALERT-FLAG
           STOP RUN.
