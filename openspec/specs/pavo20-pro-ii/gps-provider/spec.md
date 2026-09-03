# pavo20-pro-ii/gps-provider Specification

## Purpose
Governs which GPS provider the Pavo20 Pro II runs, what evidence is required before a provider
claim may be written into a config or a document, and why the rejected provider stays documented
rather than deleted.

## Requirements

### Requirement: The committed configs SHALL state the GPS provider explicitly

`gps_provider`, `gps_auto_config` and `gps_ublox_use_galileo` MUST appear as explicit `set` lines
in every committed Pavo20 Pro II config, each with an adjacent comment naming the firmware version
its default was read at.

Two of the three now equal the firmware default. At Betaflight `2025.12.2`,
`src/main/pg/gps.c` `PG_RESET_TEMPLATE(gpsConfig_t, ...)` sets `.provider = GPS_UBLOX`,
`.autoConfig = GPS_AUTOCONFIG_ON` and `.gps_ublox_use_galileo = false`. So `gps_provider` and
`gps_auto_config` will not appear in a `diff all`, and their absence would be indistinguishable
from a line dropped by a chunked paste — the failure mode `CLAUDE.md` warns about and that
`HANDOFF.md` records as having already produced one misattributed GPS fault.

This is the pinning exception in `pavo20-pro-ii/flight-config`, used deliberately: these values
decide whether the aircraft has a GPS at all, so a reader must be able to see the choice without
consulting a firmware default table.

#### Scenario: Provider survives a paste onto a freshly flashed board

- **WHEN** a committed config is pasted onto a board flashed with `2025.12.2` and a fresh
  `diff all` is captured
- **THEN** `get gps_provider`, `get gps_auto_config` and `get gps_ublox_use_galileo` return
  `UBLOX`, `ON` and `ON`, regardless of whether those lines appear in the capture

#### Scenario: A default moves in a later firmware version

- **WHEN** the aircraft is flashed to a version whose GPS defaults differ
- **THEN** the explicit lines still produce the intended values, and the comment names the version
  the previous default was checked at

### Requirement: A GPS provider claim SHALL be re-established after any change to the signal path

A statement that a provider does or does not work MUST cite an observation taken on the aircraft
*after* the most recent change to the wiring, pads or firmware it depends on. A prior session's
conclusion MUST NOT be carried forward across such a change.

The UBLOX driver depends on the flight controller's transmit line reaching the module: on the
`BETAFPVG473_V3` board that is FC pad `T2` = `PA2` into the BZ-181's RX. At `2025.12.2` the only
exit from `GPS_STATE_DETECT_BAUD` is a parsed `MON-VER` reply — `src/main/io/gps.c:1053`,
`if (gpsData.platformVersion > UBX_VERSION_UNDEF)`. There is no timeout that advances the state
machine without one, so a broken FC→module transmit line yields no GPS data at all. The NMEA path
has no such dependency: `gpsConfigureNmea()` advances out of `GPS_STATE_DETECT_BAUD`
unconditionally (`src/main/io/gps.c:987-989`).

This requirement exists because the opposite happened. "The BZ-181 never answers `MON-VER`" was
established while the module's TX was soldered to `R1` = `PA10`, contended with the O4 air unit's
SBUS output. The 2026-09-01 rewire moved the very wire the claim depended on, and the claim was
carried across it unchanged into two configs, two documents and two spec rationales. Retested on
2026-09-03, it was false.

#### Scenario: Provider verified after a rewire

- **WHEN** any GPS wire, pad or firmware version changes, and the configs claim a provider works
- **THEN** `status` reports `version =` followed by a u-blox version string rather than `unknown`,
  and the Configurator GPS tab shows a rising satellite count

#### Scenario: A provider claim cannot be supported

- **WHEN** no post-change observation exists for the claimed provider
- **THEN** `HANDOFF.md` lists it as unverified rather than the configs asserting it

### Requirement: NMEA SHALL remain documented as the recovery path

`pavo20-pro-ii/GPS_SETUP.md` MUST carry the NMEA fallback — `set gps_provider = NMEA` and
`set gps_auto_config = OFF` at a fixed 115200 — together with the reason it is the first thing to
try when GPS stops working.

UBLOX re-establishes two-way communication at every boot; NMEA never needs the FC to transmit. The
FC→module transmit path runs through a solder joint made on 2026-09-01, on an airframe that
vibrates. If that joint fails, UBLOX yields no GPS and NMEA still works.

The consequence is bounded and MUST be stated as such, so the fallback is not mistaken for a
safety mitigation: `allowArmingWithoutFix` defaults to `false`
(`src/main/pg/gps_rescue_multirotor.c:53` at `2025.12.2`), so a failed detection prevents arming
rather than allowing a launch without GPS.

#### Scenario: GPS stops working after a hard landing

- **WHEN** the Configurator GPS tab shows no satellites under UBLOX
- **THEN** `GPS_SETUP.md` gives the NMEA fallback lines, and applying them restores a satellite
  count if the module and its power are intact

#### Scenario: Fallback is not presented as a safety feature

- **WHEN** a reader looks up the NMEA fallback
- **THEN** the text states that a failed UBLOX detection blocks arming rather than permitting a
  GPS-less flight
