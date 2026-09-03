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

The same CRSF frame carries `gpsSol.numSat` as its final byte, so a satellite count is available
to the radio alongside the coordinates. Which EdgeTX telemetry sensor exposes it MUST be confirmed
on the radio rather than assumed.

#### Scenario: Drone powered indoors, no satellites

- **WHEN** the drone is powered, telemetry is flowing, and the GPS sensor reports zeros
- **THEN** the widget shows a waiting state and renders no QR code

#### Scenario: Drone powered indoors under the UBLOX provider

- **WHEN** the drone is powered indoors, the Configurator GPS tab shows `3D Fix` false with a
  satellite count below the fix threshold, and the reported latitude and longitude are non-zero
- **THEN** the widget shows a waiting state and renders no QR code, rather than encoding those
  coordinates

#### Scenario: GPS sensor absent entirely

- **WHEN** no telemetry sensor named `GPS` exists on the model
- **THEN** the widget shows a waiting state and does not error or blank the screen

#### Scenario: A rejected position is not persisted

- **WHEN** a position arrives that the widget declines to present
- **THEN** the saved fix on the SD card is left unchanged, so a later power cycle does not restore
  the rejected position as `SAVED`

### Requirement: Radio-side documentation SHALL NOT restate per-aircraft flight controller settings

Documentation under `radio/` MUST cross-reference the owning aircraft folder for any Betaflight
setting that differs between aircraft, rather than stating a value. Where it names a setting at
all, it MUST name the firmware version the value was read at.

The bundled widget README instructed the reader to set the GPS protocol to `UBLOX` with auto-baud.
Applied to the Pavo20 Pro II that was recorded here as the documented wrong answer, on the grounds
that its BZ-181 never answers a UBX `MON-VER`. **That reasoning was false**, and was disproven on
2026-09-03: the module answers `MON-VER` once its transmit path is intact, and the aircraft now
runs UBLOX deliberately. See `pavo20-pro-ii/gps-provider`.

The instruction is still wrong, for two reasons that outlast the correction:

- Auto-baud does nothing. At `2025.12.2` `gps_auto_baud` is settable from the CLI but never read
  by `src/main/io/gps.c`, so an instruction to enable it cannot have the effect it claims.
- The provider is a per-aircraft fact, not a universal one. It is established by observation on
  each airframe, and the FireFly25 and Meteor75 Pro have not been retested since.

This requirement is better evidenced by the correction than it was by the original claim. A
`radio/` document that had stated the Pavo20's protocol as `NMEA` — the correct value on
2026-09-02 — would have been silently wrong on 2026-09-03, with nothing in `radio/` to prompt
anyone to revisit it. Values that are correct today are exactly the ones that drift.

#### Scenario: A reader follows the radio setup guide for the Pavo20

- **WHEN** a reader works through `radio/README.md` looking for GPS configuration
- **THEN** they are sent to `pavo20-pro-ii/GPS_SETUP.md` and find no protocol or baud value stated
  under `radio/`

#### Scenario: A reader follows the radio setup guide for return-to-home

- **WHEN** a reader looks for GPS Rescue setup under `radio/`
- **THEN** they are sent to `pavo20-pro-ii/FAILSAFE.md`, including its untested status, rather than
  finding a second set of rescue values

#### Scenario: An aircraft's provider changes

- **WHEN** an aircraft's GPS protocol or baud is changed and its own folder is updated
- **THEN** no document under `radio/` requires a matching edit
