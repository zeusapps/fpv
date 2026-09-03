## 1. Configs

- [x] 1.1 Replace the GPS block in `pavo20-pro-ii/PAVO20PRO2_ELRS_V1.txt` (lines ~124-132): set
  `gps_provider = UBLOX`, `gps_auto_config = ON`, `gps_ublox_use_galileo = ON`, keep
  `gps_set_home_point_once = ON`, and rewrite the comment to state that the first two equal the
  `2025.12.2` default and are pinned deliberately. Delete the `Do not set gps_provider = UBLOX`
  instruction and the "value is load-bearing" claim about `gps_auto_baud`. Verify by reading back
  that no line in the file still names NMEA as the provider.
- [x] 1.2 Apply the same block to `pavo20-pro-ii/PAVO20PRO2_SBUS_V1.txt` (lines ~130-137) and
  correct its header summary at line 4, which still says "NMEA 115200". Verify with
  `grep -n -i nmea pavo20-pro-ii/PAVO20PRO2_SBUS_V1.txt` returning only intentional references.
- [x] 1.3 Paste `PAVO20PRO2_ELRS_V1.txt` onto the aircraft in chunks, then run `diff all` and
  compare against the file. Verify every `set` line matches except the deliberately absent
  `acc_calibration`. This closes the outstanding round-trip risk carried since 2026-09-03.
- [x] 1.4 Save the capture as a new dated dump under `pavo20-pro-ii/dumps/` and verify
  `git grep` finds no `mcu_id` or `signature` value from it anywhere in tracked files before
  committing.
- [x] 1.5 Confirm on the aircraft that `status` reports `version =` followed by a u-blox version
  string rather than `unknown`, and that the Configurator GPS tab shows a satellite count. A
  successful paste that broke detection would show `unknown` here.

## 2. Aircraft documentation

- [x] 2.1 Rewrite the RESOLVED header of `pavo20-pro-ii/GPS_SETUP.md`: the aircraft runs UBLOX with
  auto-config and Galileo on. Keep the pin-contention diagnosis, which is unaffected. Verify the
  file no longer asserts that the BZ-181 cannot answer `MON-VER`.
- [x] 2.2 Correct the "Note where this diverges from what works on this quad" passage in
  `GPS_SETUP.md`, which currently says BetaFPV's UBLOX-with-auto-config steps leave the driver
  stuck in `DETECT_BAUD`. Those steps now largely describe what the aircraft actually runs; what
  remains wrong is only the auto-baud element. Verify the passage names `gps_auto_baud` as inert
  at `2025.12.2` rather than as necessary.
- [x] 2.3 Add the NMEA recovery section to `GPS_SETUP.md`: the two fallback lines, the reason
  (UBLOX needs the FC→module transmit line at every boot, NMEA needs nothing from the FC), and the
  bounded consequence (a failed detection blocks arming). Verify it states the full power cycle
  needed for the module's RAM-layer config to revert.
- [x] 2.4 Update `HANDOFF.md`: move GPS provider to UBLOX in the configuration section, delete the
  now-closed "Optional: retest the UBLOX provider" item, move the first outdoor cold-start fix out
  of NOT VERIFIED with its balcony caveat intact, and correct the `gps_auto_baud` entry under
  *Facts that cost real time to establish* to say the value is inert, not load-bearing. Verify by
  re-reading that no remaining sentence claims the module cannot answer `MON-VER`.
- [x] 2.5 Add a fact to `HANDOFF.md`: a claim about hardware behaviour expires when the signal path
  it depends on changes. Verify it names this instance — the claim survived a rewire of the exact
  wire it rested on, into six files.

## 3. Radio and widget

- [x] 3.1 Delete `/LOGS/gpsqr_last.txt` from the radio's SD card so the no-fix Mali position is not
  restored as `SAVED`. Verify by power-cycling the radio with no drone powered and confirming the
  widget shows its waiting state.
- [x] 3.2 Add the defect to `radio/CODE_REVIEW.md` under *Found after the review, not yet fixed*:
  `hasFix()` at `main.lua:50` guards only against `(0,0)`, the UBLOX no-fix signature is non-zero
  coordinates, the observed value was `14.786703, -7.396605` on 2026-09-03, and the fix direction
  is the satellite count that `crsfFrameGps()` already sends in the same CRSF frame. Verify it
  records that the EdgeTX sensor name is unconfirmed and must not be guessed.
- [x] 3.3 Add the operating rule to `radio/README.md` alongside the existing shared-save-file rule:
  a displayed position is only trustworthy if the aircraft had a 3D fix when it was sent. Verify
  `grep -n -i "nmea\|ublox\|115200" radio/` returns no aircraft protocol or baud value stated under
  `radio/`, per the spec requirement.

## 4. Verification on the aircraft

- [x] 4.1 Outdoors with clear sky, confirm 3D fix, at least 8 satellites held steady, and an
  altitude consistent with the known site elevation of ~124 m. Record the date and the numbers in
  `HANDOFF.md`.
- [x] 4.2 Check the Configurator Signal Info list for Galileo satellites specifically. If none
  appear with `gps_ublox_use_galileo = ON`, record that rather than assuming the setting took
  effect. Non-blocking — the fix works either way.
- [x] 4.3 Confirm `HANDOFF.md` still lists GPS Rescue as configured-but-untested and in-flight fix
  quality as unproven. This change verifies a stationary fix under partial sky and must not be
  read as clearing the rescue test.

## 5. Close out

- [x] 5.1 Run `openspec validate adopt-ublox-gps-provider` and confirm it passes with all tasks
  checked.
- [x] 5.2 Archive the change so the delta specs are synced into `openspec/specs/`. Do not hand-edit
  `openspec/specs/pavo20-pro-ii/flight-config/spec.md` or
  `openspec/specs/radio/gpsqr-widget/spec.md` — archiving applies both deltas and creates
  `pavo20-pro-ii/gps-provider`. Verify afterwards that the new capability's `## Purpose` is present
  rather than a `TBD` placeholder.
