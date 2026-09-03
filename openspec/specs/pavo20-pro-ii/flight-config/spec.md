# pavo20-pro-ii/flight-config Specification

## Purpose
What a committed, re-pasteable Betaflight config for the Pavo20 Pro II must guarantee: that pasting
it into a flying aircraft cannot silently degrade it, and that it describes the aircraft as
currently flown rather than as it was on the day the file was captured.

## Requirements

### Requirement: A committed config SHALL NOT carry accelerometer calibration

`PAVO20PRO2_ELRS_V1.txt` and `PAVO20PRO2_SBUS_V1.txt` MUST NOT contain `set acc_calibration`,
`set acc_trim_pitch` or `set acc_trim_roll`. Their absence means the values already on the board
survive a paste, because `diff all` format only writes what it names.

These three values describe how the flight controller sits in *this* airframe at the moment it was
levelled. They are invalidated by anything that disturbs the board — the 2026-09-01 GPS/LED rewire
did exactly that, and the re-level that followed moved `acc_calibration` from `-66,3,-68,1` to
`-37,-87,-45,1` and cleared both trims. The committed files still carry the pre-rewire triplet.

`CLAUDE.md` already forbids copying these between aircraft. The stronger rule this requirement adds
is that they go stale *within a single aircraft*, on a timescale set by maintenance rather than by
anything visible in the file. Nothing in a config file records when its calibration was taken, so a
reader cannot tell a fresh one from a two-rewires-old one.

The failure is silent, and that is what makes it serious. A bad calibration produces no CLI error,
no failed arm and no warning. It shows up as a horizon that drifts in Angle mode and as a wrong
level reference for GPS Rescue — which, per `HANDOFF.md` under *GPS Rescue*, is configured but has
never been tested, so the first flight that would reveal the fault is also the first flight that
depends on the feature.

Falsifying observation: `grep -c "^set acc_" PAVO20PRO2_ELRS_V1.txt` returns anything other than 0.
Match the `set` lines, not bare `acc_` — the comment left in their place names the settings it
removed, and would otherwise read as a violation.

#### Scenario: Pasting onto a freshly levelled aircraft

- **WHEN** the config is pasted into an aircraft that has just been re-levelled
- **THEN** `get acc_calibration` afterwards returns the values produced by that re-level, unchanged

#### Scenario: Calibration is obtained rather than assumed

- **WHEN** a reader follows `SETUP_GUIDE.md` to bring this aircraft up from a bare board
- **THEN** the procedure requires an explicit accelerometer levelling step after the paste, and
  does not present any committed number as a usable calibration

### Requirement: A committed config SHALL describe the OSD layout actually in use

The OSD element positions in a committed config MUST match those in the newest capture in `dumps/`.
Where they diverge, either the file is corrected or the divergence is recorded in `HANDOFF.md` with
the reason.

As of the 2026-09-03 baseline, eight elements had moved — `gps_sats`, `home_dist`, `gps_speed`,
`gps_lat`, `gps_lon`, `altitude`, `core_temp` and `sys_vtx_temp` — from a left-hand column into a
top strip. All eight retain profile bit 1, so nothing was hidden; the file simply stopped matching.

This is not a flight-safety item and is not claimed as one. It matters because the OSD is the only
place GPS state is visible in flight, and `HANDOFF.md` records that "no GPS in the OSD" and "GPS
showing zeros" are different faults with different causes. A stale layout in the committed file
makes it useless as the reference for telling those two apart.

Positions are encoded integers; `docs/betaflight-reference.md` carries the formula, and a value
below 2048 is hidden.

#### Scenario: An element is moved on the aircraft

- **WHEN** an element is repositioned in the Configurator OSD tab and a new `diff all` is captured
- **THEN** the committed config is updated to the captured position, or `HANDOFF.md` says why not

#### Scenario: Round-trip after a paste

- **WHEN** the config is pasted and a fresh `diff all` is taken
- **THEN** no `osd_*_pos` value differs between the file and the capture

### Requirement: A committed config SHALL NOT restate firmware defaults

A line whose value equals the firmware default for the version named in `HANDOFF.md` MUST NOT
appear in a committed config, unless an adjacent comment says why it is there.

Three such lines were identified on 2026-09-03: `set gps_auto_baud = OFF` and `set rates_type =
ACTUAL`, both confirmed equal to the 2025.12.2 default by `get`, and `set auto_profile_cell_count
= 0` on profile 2.

The cost is not the line, it is what the line implies. `diff all` emits only what differs from
default, so a reader who knows the format reads every line in these files as a deliberate
deviation. A default restated as though it were a choice invites someone to defend it, and
`CLAUDE.md` warns that pastes are chunked and that lines get dropped — a dropped line that was
doing nothing produces a hunt for a fault that does not exist.

`gps_auto_baud` was offered here as the sharp case: load-bearing as a *value* and inert as a
*line*. That reading was wrong, and how it was wrong is the more useful lesson. At `2025.12.2` the
field exists in `gpsConfig_t` (`src/main/pg/gps.h`) and is settable from the CLI
(`src/main/cli/settings.c:1137`), which is why `get gps_auto_baud` prints `OFF` — but
`src/main/io/gps.c` never reads it. The UBLOX driver baud-scans unconditionally: three `MON-VER`
attempts per rate at 330 ms each (`GPS_BAUDRATE_TEST_COUNT` and `GPS_CONFIG_BAUD_CHANGE_INTERVAL`,
`src/main/io/gps.c:90` and `:92`), stepping down through the six rates of `gpsInitData[]`
(`src/main/io/gps.c:109-116`) and wrapping. The value is inert as well as the line.

**`get` printing a value proves a setting is settable, not that anything reads it.** Only the
firmware source separates a live default from a dead one, and `get` cannot make that distinction
at all.

`gps_provider` and `gps_auto_config` replace it as the sharp case, and are a better one. At
`2025.12.2` both equal the firmware default — `.provider = GPS_UBLOX` and
`.autoConfig = GPS_AUTOCONFIG_ON` in `PG_RESET_TEMPLATE(gpsConfig_t, ...)`, `src/main/pg/gps.c` —
and both decide whether the aircraft has a GPS at all. A default that is genuinely load-bearing is
exactly what the exception below is for.

The exception exists because a default can move between firmware versions. A restated default that
is pinned on purpose is acceptable when the comment says so.

#### Scenario: A default is deliberately pinned

- **WHEN** a setting is written explicitly even though it matches the current default
- **THEN** an adjacent comment states which firmware version the default was checked against, and
  why the line is being kept

#### Scenario: Removing an inert line does not change behaviour

- **WHEN** the three identified lines are removed and the config is pasted
- **THEN** `get gps_auto_baud`, `get rates_type` and `get auto_profile_cell_count` return the same
  values as they did before the removal

#### Scenario: A setting is settable but never read

- **WHEN** a config line is defended on the grounds that `get` returns the expected value
- **THEN** the firmware source for the version in `HANDOFF.md` is checked for a read of that
  field, and a field nothing reads is recorded as inert rather than as load-bearing

### Requirement: Profile selection SHALL be left to cell-count auto-selection

A committed config MUST NOT be edited in order to change which PID profile is active at the end of
a paste. The trailing `profile` and `rateprofile` lines are left as captured.

`changePidProfileFromCellCount`, in `src/main/config/config.c` at tag `2025.12.2`, runs on every
battery connect while disarmed. It returns early if the active profile's `auto_profile_cell_count`
already matches the detected cell count or is the STAY value; otherwise it scans the remaining
profiles and switches to the first whose `auto_profile_cell_count` matches exactly. Profile 0
(`O4Pro3S`) declares `3` and profile 1 (`O4Pro4S`) declares `4`, so the pack decides, not the file.

This requirement records a disproved hypothesis rather than imposing a behaviour. The trailing
`profile 0` line was read as stranding a 4S aircraft on the 3S tune. It does not, and "fixing" it
would be a change made against the firmware's actual behaviour. `HANDOFF.md` notes that several
confident diagnoses in this repo were overturned by checking; this is one of them, written down so
that it is not rediscovered as a bug.

Profile 2 (`O4 Soft`) carries the STAY value and is therefore manual-selection-only by design: once
chosen it survives battery connects. That is intended and MUST be preserved.

#### Scenario: 4S pack on a config that ends selecting profile 0

- **WHEN** the config is pasted, leaving profile 0 active, and a 4S pack is connected while disarmed
- **THEN** the aircraft switches to profile 1 (`O4Pro4S`) and sounds the confirmation beeps

#### Scenario: A manually selected soft profile is not overridden

- **WHEN** profile 2 (`O4 Soft`) is selected by hand and a pack of any cell count is connected
- **THEN** profile 2 remains active
