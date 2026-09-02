# FireFly25

2.5" quad. The least documented aircraft in this repo — currently just a defaults capture.

| Item | Value |
|---|---|
| Craft name | `Firefly` |
| Board target | `FLYWOOF405S_AIO` |
| Manufacturer ID | `FLWO` |
| MCU | STM32F405 |
| Firmware | Betaflight 2025.12.2, MSP API 1.47 |
| Motor protocol | DSHOT300, bidirectional DShot ON |
| Receiver | ELRS / CRSF on UART3 |
| Video | DJI air unit on UART6 (`131073` = VTX_MSP + MSP) |
| GPS | on UART4 (`serial UART4 2 115200 115200`) |
| Features | GPS, LED_STRIP, OSD |

## Files

- `dumps/FireFly25Mini-defaults.txt` — captured configuration

## Switch layout

Same convention as the other aircraft in this repo:

| Switch | Position | Mode |
|---|---|---|
| AUX1 / CH5 | high | ARM |
| AUX2 / CH6 | low | ANGLE |
| AUX2 / CH6 | high | TURTLE |
| AUX3 / CH7 | high | PREARM |
| AUX4 / CH8 | high | BEEPER |

## Note

This aircraft's GPS works and reports satellite counts, which made it a useful control while
diagnosing the Pavo20 Pro II — "the FireFly shows zeros" was the observation that established
zeros mean a working GPS without a fix, while *no GPS elements at all* means the flight controller
is parsing nothing. See `../pavo20-pro-ii/GPS_SETUP.md`.

If this quad gets flown seriously, it wants the same treatment as the Pavo20: a hardware reference,
a setup guide, and tuned config variants rather than a bare defaults dump.
