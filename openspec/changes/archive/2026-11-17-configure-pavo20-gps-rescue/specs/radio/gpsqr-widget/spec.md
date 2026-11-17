## MODIFIED Requirements

### Requirement: An absent or invalid fix SHALL NOT be presented as a position

The widget MUST distinguish "no fix yet" from any position it is handed, and MUST NOT present a
position that is not backed by a valid fix. Coordinates of `0, 0` are one signature of an
unacquired receiver, not the only one.

The original rule assumed they were the only one. Under the NMEA provider a receiver with no fix
reports zeros — `README.md` and `pavo20-pro-ii/GPS_SETUP.md` record that zeros mean
working-without-fix while missing elements mean nothing is being parsed — and encoding
`0.000000,0.000000` into a QR would send the user to the Gulf of Guinea.

**Under the UBLOX provider that signature does not appear.** At Betaflight `2025.12.2` the NAV-PVT
handler assigns position unconditionally and records fix validity separately
(`src/main/io/gps.c:2244-2256`): `gpsSol.llh.lat` and `.lon` are written from the frame, then
`gpsSetFixState(ubxHaveNewValidFix)` is called with a flag derived from `fixType == FIX_3D`. The
CRSF telemetry frame then transmits those coordinates with no fix check of its own
(`crsfFrameGps()`, `src/main/telemetry/crsf.c`). So a receiver with no fix sends the radio
plausible, non-zero, entirely wrong coordinates.

Observed on 2026-09-03, the first time the Pavo20 Pro II ran UBLOX: with 3 satellites, `3D Fix`
false and PDOP 99.9, the aircraft reported `14.786703, -7.396605` — a point in Mali. The widget's
`(0, 0)` guard passed it, displayed it, and wrote it to the SD card. This is worse than the
accepted shared-save-file defect: that one shows a real position belonging to some aircraft, this
one shows a position no aircraft has ever occupied.

The same CRSF frame carries `gpsSol.numSat` as its final byte, so a satellite count is available to
the radio alongside the coordinates. **That sensor is named `Sats`**, confirmed on the V12 MAX in
the field on 2026-09-03 while reading above 20. The widget MUST require a satellite count of at
least 5 in addition to non-zero coordinates before presenting or persisting a position.

The absent-sensor case MUST NOT be conflated with a genuine zero. EdgeTX yields `0` for a
telemetry sensor name it has not discovered, which is indistinguishable from a receiver reporting
no satellites; both mean the position cannot be trusted, but only one of them is a setup fault the
user can fix. The widget MUST therefore report the two distinctly, so that a screen showing no
position is diagnosable rather than merely blank.

#### Scenario: Drone powered indoors, no satellites

- **WHEN** the drone is powered, telemetry is flowing, and the GPS sensor reports zeros
- **THEN** the widget shows a waiting state and renders no QR code

#### Scenario: Drone powered indoors under the UBLOX provider

- **WHEN** the drone is powered indoors, the Configurator GPS tab shows `3D Fix` false with a
  satellite count below the fix threshold, and the reported latitude and longitude are non-zero
- **THEN** the widget shows a waiting state and renders no QR code, rather than encoding those
  coordinates

#### Scenario: Satellite count below the trust threshold

- **WHEN** the `Sats` sensor reports fewer than 5 satellites while the GPS sensor reports non-zero
  coordinates
- **THEN** the widget shows a waiting state naming the satellite count, renders no QR code, and
  leaves the saved fix on the SD card unchanged

#### Scenario: Satellite sensor not present on the model

- **WHEN** no telemetry sensor named `Sats` has been discovered for the model
- **THEN** the widget reports that the sensor is missing, distinctly from a low satellite count,
  and presents no position

#### Scenario: GPS sensor absent entirely

- **WHEN** no telemetry sensor named `GPS` exists on the model
- **THEN** the widget shows a waiting state and does not error or blank the screen

#### Scenario: A rejected position is not persisted

- **WHEN** a position arrives that the widget declines to present
- **THEN** the saved fix on the SD card is left unchanged, so a later power cycle does not restore
  the rejected position as `SAVED`
