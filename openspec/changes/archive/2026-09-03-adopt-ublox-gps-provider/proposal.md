## Why

The Pavo20 Pro II ran the NMEA GPS provider because the BZ-181 was believed never to answer a UBX
`MON-VER`. That belief was formed *before* the 2026-09-01 rewire, while the GPS module's TX shared
`R1 (PA10)` with the O4 air unit's SBUS output — the contention `HANDOFF.md` already flagged as
never cleanly isolated from the UBLOX failure.

Retested on 2026-09-03, after the rewire onto `T2 (PA2)`: **UBLOX works.** The module answers
`MON-VER`, auto-config completes, and the aircraft holds a 3D fix on 10 satellites at a correct
position. The claim is disproven, and it is currently written into six files — including an
explicit `Do not set gps_provider = UBLOX` instruction in two committed configs and the rationale
under two spec requirements.

Switching provider also changed the *shape* of a no-fix reading, which exposed a live defect in the
GPSQR widget.

## What Changes

- **The Pavo20 Pro II adopts the UBLOX provider.** `gps_provider = UBLOX`, `gps_auto_config = ON`,
  `gps_ublox_use_galileo = ON`, applied from the Configurator and confirmed on the aircraft.
- **BREAKING for anyone pasting the current configs**: `PAVO20PRO2_ELRS_V1.txt` and
  `PAVO20PRO2_SBUS_V1.txt` currently set NMEA and instruct the reader not to use UBLOX. Both are
  now wrong. Two of the three replacement values are firmware defaults, so they will *not* appear
  in a future `diff all` — they must be pinned explicitly with a comment.
- **NMEA is retained as the documented recovery path, not deleted.** UBLOX requires the FC→module
  TX line to work at every boot; NMEA requires nothing from the FC. That TX path runs through a
  solder joint made on 2026-09-01.
- **`gps_auto_baud` is reclassified as inert.** It is settable from the CLI but never read by the
  firmware at 2025.12.2. `HANDOFF.md` and the flight-config spec both call its *value*
  load-bearing; it is not.
- **A new GPSQR widget defect is recorded** (not fixed here): the widget presented and saved a
  no-fix position. Fixing it needs an EdgeTX check on the radio first.

## Capabilities

### New Capabilities

- `pavo20-pro-ii/gps-provider`: which GPS provider the aircraft runs, what evidence is required
  before a provider claim may be written down, and why the alternative stays documented.

### Modified Capabilities

- `pavo20-pro-ii/flight-config`: the requirement *A committed config SHALL NOT restate firmware
  defaults* keeps its rule, but its worked example is falsified. `gps_auto_baud` was offered as the
  sharp case of "load-bearing as a value, inert as a line"; it is now inert as both.
  `gps_provider` and `gps_auto_config` replace it, and are a better example — genuinely
  load-bearing settings that now equal the default, which is exactly what the pinning exception
  exists for.
- `radio/gpsqr-widget`: two requirements keep their rules and lose their rationale.
  *An absent or invalid fix SHALL NOT be presented as a position* assumed the only invalid-fix
  signature is `0, 0`. That held under NMEA. Under UBLOX, NAV-PVT carries lat/lon regardless of fix
  validity, so a receiver with no fix reports plausible non-zero coordinates — observed on
  2026-09-03 as `14.786703, -7.396605`, in Mali. The widget's `(0,0)` guard satisfied the spec as
  written and still displayed and saved a position no aircraft has ever been at.
  *Radio-side documentation SHALL NOT restate per-aircraft flight controller settings* keeps its
  rule too, but its supporting evidence — the bundled README's UBLOX advice being wrong because the
  BZ-181 cannot complete detection — is no longer true. The advice is still wrong, for two better
  reasons.

## Impact

Configs (must be pasted and re-captured to verify):
- `pavo20-pro-ii/PAVO20PRO2_ELRS_V1.txt` — GPS block and its comment
- `pavo20-pro-ii/PAVO20PRO2_SBUS_V1.txt` — same block, plus the header summary at line 4

Documentation:
- `pavo20-pro-ii/GPS_SETUP.md` — the RESOLVED header and the BetaFPV-divergence note
- `HANDOFF.md` — aircraft configuration, verified/not-verified lists, the now-closed "retest the
  UBLOX provider" item, the first-outdoor-fix item, and the `gps_auto_baud` entry under
  *Facts that cost real time to establish*
- `radio/CODE_REVIEW.md` — new entry under *Found after the review, not yet fixed*

Specs:
- `openspec/specs/pavo20-pro-ii/flight-config/spec.md`
- `openspec/specs/radio/gpsqr-widget/spec.md`

Not changed: `openspec/specs/pavo20-pro-ii/uart-allocation/spec.md`. Its reference to
"bit-corrupted NMEA" describes what was observed in 2026-09 under the provider in use at the time,
and remains accurate.

No aircraft behaviour outside GPS is touched. No PID, rate, motor or failsafe value changes.
