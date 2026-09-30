# Spec Delta

## Purpose

What a committed, re-pasteable Betaflight config for the Meteor75 Pro must guarantee: that pasting
it cannot silently degrade the aircraft, that it describes the aircraft as currently flown, and
that its rate curves and battery settings behave as their numbers suggest on the packs in use.

All firmware citations below were read at Betaflight tag `4.5.1`, the version the aircraft reports
(`# Betaflight / STM32G47X (SG47) 4.5.1 Dec  6 2024`). Re-read them before relying on this spec on
any other version.

## ADDED Requirements

### Requirement: A committed config SHALL NOT carry accelerometer calibration

`M75_PRO_ELRS_V1.txt` and `M75_PRO_SBUS_V1.txt` MUST NOT contain `set acc_calibration`,
`set acc_trim_pitch` or `set acc_trim_roll`. `diff all` format only writes what it names, so their
absence leaves whatever calibration is on the board intact through a paste.

The committed Meteor files carried three different triplets: `24,15,46,1` (factory dump),
`-12851,-6,14,1` (the two V1 files) and `-17621,-71,65,1` (`M75_hello_radio_v12.txt`, and still on
the aircraft on 2026-09-29). Nothing in any file says which levelling produced which, so none of
them can be trusted as current. The same rule already applies to the Pavo20
(`pavo20-pro-ii/flight-config`); it is stated here per-aircraft because promoting it fleet-wide is
a separate decision.

Falsifying observation: `grep -c "^set acc_" meteor75-pro/M75_PRO_*_V1.txt` returns anything other
than 0 for either file.

#### Scenario: Pasting onto a levelled aircraft

- **WHEN** a committed config is pasted into an aircraft that has just been levelled
- **THEN** `get acc_calibration` afterwards returns the values produced by that levelling, unchanged

#### Scenario: Calibration is obtained rather than assumed

- **WHEN** a reader follows `meteor75-pro/README.md` to apply a committed config
- **THEN** the procedure requires Setup > Calibrate Accelerometer, quad level, after the paste

### Requirement: A committed config SHALL be verifiable against a dated capture of the aircraft

`meteor75-pro/dumps/` MUST hold a `diff all` capture of the aircraft, with its date in the filename
and `mcu_id` redacted, taken after the committed config was last applied. Every setting a committed
config names MUST either match that capture or be listed in `HANDOFF.md` with the reason it
differs.

This is the requirement whose absence let the Meteor75 drift. Between 2026-01-30 and 2026-09-29
the aircraft lost its PID tune, gained a 1150°/s linear rate profile, a 3-position rate switch and
a new battery ceiling — all through the Configurator — while `HANDOFF.md` recorded it as "stable,
no outstanding work". No file was wrong on the day it was written; every file became wrong without
a signal.

The check is a comparison against the aircraft, not against another file. `status` or a
Configurator screen does not satisfy it: a `diff all` captured from the aircraft does.

Falsifying observation: a fresh `diff all` from the aircraft differs from the committed config in
any `set`, `aux`, `adjrange` or `serial` line not listed in `HANDOFF.md`.

#### Scenario: Round-trip after a paste

- **WHEN** a committed config is pasted, the aircraft is levelled, and a fresh `diff all` is taken
- **THEN** it differs from the committed config only in `acc_calibration`, `mcu_id` and lines
  listed in `HANDOFF.md`

#### Scenario: A setting is changed in the Configurator

- **WHEN** any setting is changed on the aircraft through the Configurator and kept
- **THEN** a new dated capture is committed and the config is updated to match it, or `HANDOFF.md`
  records the divergence and why

### Requirement: Every rate profile SHALL have a centre sensitivity below its maximum rate

For every rate profile and every axis, a committed config using `rates_type = ACTUAL` (the 4.5.1
default, `src/main/fc/controlrate_profile.c:48`) MUST satisfy `rc_rate < srate`, and SHALL keep
`rc_rate` at or below 10 (100°/s).

`applyActualRates`, `src/main/fc/rc.c:209-219` at 4.5.1:

```c
const float centerSensitivity = currentControlRateProfile->rcRates[axis] * 10.0f;
const float stickMovement = MAX(0, currentControlRateProfile->rates[axis] * 10.0f - centerSensitivity);
const float angleRate = rcCommandf * centerSensitivity + stickMovement * expof;
```

Expo acts only through `stickMovement`. When `rc_rate >= srate` that term is clamped to zero, the
curve becomes a straight line through `rc_rate * 10` at full stick, expo does nothing, and the
configured maximum is ignored. On 2026-09-29 rate profile 0 carried `roll_rc_rate = 115` with
`roll_srate = 72`: 115°/s at 10% stick and 1150°/s at full, against a stated maximum of 720. It was
the direct cause of the "too sharp, no room for smooth turns" report.

The Configurator labels `rc_rate` "Center Sensitivity" and displays it in °/s, next to "Max Rate",
which makes this easy to set by accident. The ceiling of 10 is a margin, not a firmware limit
(`ratesSettingLimits[RATES_TYPE_ACTUAL]` allows 200, `controlrate_profile.c:73`).

Falsifying observation: for any profile, the Configurator Rates tab plot is a straight line, or
the rate at 10% stick exceeds 10% of the maximum rate.

#### Scenario: Soft centre on every switch position

- **WHEN** the aircraft is flown in Acro on each CH9 position and the roll stick is moved about 10%
- **THEN** the roll rate is below 15°/s on every position (rate curves in `design.md`)

#### Scenario: A profile violating the rule is rejected in review

- **WHEN** a committed config contains a rate profile with `*_rc_rate` greater than or equal to
  `*_srate` on any axis
- **THEN** the config is not merged

### Requirement: The cell-voltage ceiling SHALL detect a freshly charged pack as present, as 1S

`vbat_max_cell_voltage` MUST be strictly greater than the highest resting voltage of a freshly
charged pack in use. For the Lava 2 LiHV 580 and 680 mAh 1S packs (4.35 V full charge) the
committed value is `450`.

At 4.5.1 this one setting gates both battery detection and cell counting.
`isVoltageFromBattery`, `src/main/sensors/battery.c:190-197`, treats a reading as a battery only if
it is at or below `vbatmaxcellvoltage`, or above `2 * vbatnotpresentcellvoltage` (6.00 V). A 1S
pack reading above the ceiling falls in the gap and is **not present**: no cell count, no warning
thresholds, no PID-profile auto-selection. `batteryUpdatePresence`, `battery.c:199-243`, runs only
when the reading enters the band, and counts cells as

```c
unsigned cells = (voltageMeter.displayFiltered / batteryConfig()->vbatmaxcellvoltage) + 1;
```

(`battery.c:210`), so a reading exactly equal to the ceiling counts as 2S and sets 2S warning
thresholds. With the repo's former `435`, a fresh LiHV pack at 4.36 V is not detected on plug-in,
becomes detected only once it sags into the band — possibly in flight, when
`changePidProfileFromCellCount` is skipped because the aircraft is armed (`battery.c:217`) — and at
exactly 4.35 V is counted as 2S. The factory `440` leaves 0.05 V of margin; the `450` found on the
aircraft leaves 0.15 V. The firmware default is `430` (`battery.h:36`), which is wrong for LiHV.

Falsifying observation: with a freshly charged pack connected and the aircraft disarmed, the OSD
or Configurator does not show a 1S battery with a voltage, or `status` reports a cell count other
than 1.

#### Scenario: Fresh LiHV pack on plug-in

- **WHEN** a Lava 2 LiHV pack charged to 4.35 V is connected to the disarmed aircraft
- **THEN** the battery is detected immediately as 1S and the PID profile with
  `auto_profile_cell_count = 1` becomes active

#### Scenario: A higher-voltage pack is introduced

- **WHEN** a pack type with a higher full-charge voltage is added to the fleet
- **THEN** `vbat_max_cell_voltage` is re-checked against that pack's resting voltage before it flies

### Requirement: The active PID profile SHALL be reachable by cell-count selection

At the end of a paste the active PID profile MUST be one whose `auto_profile_cell_count` is `1`, and
the GF 40mm tune MUST live in that profile. No other profile may carry `auto_profile_cell_count = 1`.

`changePidProfileFromCellCount`, `src/main/config/config.c:843-866` at 4.5.1, runs on battery
detection while disarmed. It returns immediately if the **current** profile's
`auto_profile_cell_count` equals the cell count **or is STAY** (`config.c:845`). STAY is the
default for every profile (`src/main/flight/pid.c:191`). So a quad left on a default profile stays
there on every battery connect; auto-selection cannot rescue it. `M75_hello_radio_v12.txt` ended
its paste on `profile 1` — default PIDs plus `crash_recovery = ON` — and nothing would have moved
it back to the tune in profile 0.

This is the Pavo20's cell-count mechanism working in the opposite direction, and is recorded so
that neither case is mistaken for the other.

Falsifying observation: after the paste and a battery connect, `status` or the OSD profile element
shows a PID profile other than the one named `GF 40mm`.

#### Scenario: Paste then battery connect

- **WHEN** a committed config is pasted and a 1S pack is connected while disarmed
- **THEN** PID profile 0 (`GF 40mm`) is active and `get p_roll` returns `64`

#### Scenario: A default profile is selected by hand

- **WHEN** a profile with the STAY value is selected in the Configurator and a pack is connected
- **THEN** that profile remains active — the reason the committed config must not end on one
