# Reconcile the Pavo20 flight configs with the flying aircraft

## Why

The 2026-09-03 `diff all` baseline (`dumps/…20260903… - current.txt`, commit `1ea8b52`) was
captured to replace a pre-rewire dump. It also established that `PAVO20PRO2_ELRS_V1.txt` — the file
`HANDOFF.md` names as what the aircraft is running — no longer describes the aircraft.

One of the differences is not cosmetic. Both committed Pavo20 configs carry
`set acc_calibration = -66,3,-68,1`, which was taken **before** the 2026-09-01 GPS/LED rewire. The
aircraft has since been re-levelled and reads `-37,-87,-45,1`, and the same re-level cleared
`acc_trim_pitch`/`acc_trim_roll`, which the files still set. Re-pasting either file today would
overwrite a valid accelerometer calibration with one from a different physical state of the
airframe, and would do it silently — there is no error, the quad still arms, and the damage shows
up as a drifting horizon in Angle mode and a wrong level reference for the GPS Rescue that
`HANDOFF.md` under *GPS Rescue* is about to test.

This is a general defect that the Pavo20 merely exposed: a per-board calibration captured into a
committed file is correct only until the next re-level, and nothing marks it stale.

## What Changes

- **BREAKING (to the paste workflow):** remove `acc_calibration`, `acc_trim_pitch` and
  `acc_trim_roll` from the committed Pavo20 configs. A config that cannot carry a calibration
  cannot carry a stale one. Pasting then *requires* a re-level as an explicit step rather than
  inheriting whatever was true on the capture date.
- Refresh the 8 drifted OSD element positions in both Pavo20 configs from the 2026-09-03 baseline,
  so the files reproduce the layout actually in use.
- Drop three lines that match the firmware default and therefore do nothing:
  `set gps_auto_baud = OFF` and `set rates_type = ACTUAL` (both confirmed by `get` on 2026-09-03),
  and `set auto_profile_cell_count = 0` on profile 2.
- Correct `GPS_SETUP.md:880`, which states that `auto_profile_cell_count` selects **profile 1** on
  a 3S pack. That was true of the pre-rewire profile order; the profiles have since been swapped
  and renamed, and 3S now selects **profile 0** (`O4Pro3S`).
- Record the UART allocation constraint that caused the original GPS fault, which `HANDOFF.md`
  item 3 has been asking for since the OpenSpec seed.

Explicitly **not** changed: the trailing `profile 0` / `rateprofile 0` selection lines. These were
initially suspected of stranding a 4S aircraft on the 3S tune. They do not —
`changePidProfileFromCellCount` in `src/main/config/config.c` at tag `2025.12.2` runs on every
battery connect while disarmed and switches to the profile whose `auto_profile_cell_count` matches
the detected cells, overriding the CLI selection. Profile 1 declares `4`, so a 4S pack selects
`O4Pro4S` on its own. Left alone deliberately, and recorded so the question is not reopened.

## Capabilities

### New Capabilities

- `pavo20-pro-ii/flight-config`: what a committed, re-pasteable config for this aircraft must
  guarantee — that pasting it cannot silently degrade a calibrated airframe, and that it describes
  the aircraft as flown rather than as captured.
- `pavo20-pro-ii/uart-allocation`: the pin and UART constraints on the Cube G4 board that a config
  must not violate, chief among them that the GPS must not share a UART with the O4 air unit's
  SBUS output.

### Modified Capabilities

None. `radio/gpsqr-widget` is untouched.

## Impact

- `pavo20-pro-ii/PAVO20PRO2_ELRS_V1.txt` — flying config, edited
- `pavo20-pro-ii/PAVO20PRO2_SBUS_V1.txt` — never pasted or flown, carries the identical stale
  values, edited the same way
- `pavo20-pro-ii/GPS_SETUP.md` — one factual correction
- `pavo20-pro-ii/SETUP_GUIDE.md` — re-level becomes a required step after pasting
- `pavo20-pro-ii/README.md` — note that configs deliberately carry no calibration

**Known gap, deliberately out of scope.** Every other committed config in the repo has the same
defect — `M75_hello_radio_v12.txt`, `M75_PRO_CLAUDE_CODE_V1.txt`,
`M75_PRO_RADIOMASTER_POCKET_V1.txt` and the FireFly25 defaults capture all carry
`acc_calibration`. The Meteor75 is recorded as stable with no outstanding work and is not being
touched on the strength of a defect found on another aircraft. If this change proves out, promoting
the requirement to a fleet-wide capability is the natural follow-up.

**No test suite.** Verification is a paste into a real flight controller followed by a bench check
and a flight, per `CLAUDE.md`. The acceptance evidence is in the spec scenarios.
