# Handoff — state of the repo as of 2026-11-17

Written so a session with no prior context can pick this up. Read this, then
`docs/betaflight-reference.md`, then the folder for whichever aircraft you are working on.

**This file shrinks as work resolves.** A finished item is deleted from it, not ticked off — how it
was finished is in the git history and in the change under `openspec/`. What survives a resolution
is only what is still true and still needed: a standing fact about the aircraft, or something ruled
out that would otherwise be re-investigated. Those go to **Facts that cost real time to establish**
at the bottom, never to a growing list of done items.

Because items are deleted, they renumber. Cross-reference this file by section title, not by
number — `HANDOFF.md` under *GPS Rescue*, not "item 2".

## Where things stand

| Aircraft | Status |
|---|---|
| **Pavo20 Pro II** | Out of service. The 4S AIO burned; the pilot suspects a MOSFET fault. On pause, with no repair plan. See *Pavo20 Pro II — out of service*. |
| **Meteor75 Pro** | Configs rewritten 2026-09-29 after the aircraft was found to match no committed file. Flown 2026-09-30, six packs, pilot reports it much better. SBUS variant untested; accelerometer suspect. |
| **Meteor75 Pro II** | Setup closed 2026-11-17. The pilot flies it regularly and reports it "exceptional". |
| **FireFly25** | Bare defaults capture only. Not actively worked on. |
| **Radio (V12 MAX)** | GPSQR widget bench-verified 2026-09-03. Parked: no aircraft in service has GPS. |
| **Radio (Oxbot R1)** | On trial against the V12 from 2026-09-30. Linked to both aircraft by binding phrase. Both aircraft bench-checked and flown on it (2026-10-01). Rescue switch works; R1 has alarms. |

## Meteor75 Pro II — in service

The aircraft reports `BETAFPVG473`, BMI270, and Betaflight `2025.12.5-alpha`, commit `eb2bb5a33`.
The tune is BetaFPV's `GF 1811`. Board yaw is -90 degrees.
[M75_PRO_II_ELRS_V1.txt](meteor75-pro-ii/M75_PRO_II_ELRS_V1.txt) is the applied configuration.
SC low/middle/high selects Pro II Stock / Cine / Park on the Oxbot R1.

The authoritative capture is the 2026-10-12 19:59:33 `current` file in
[meteor75-pro-ii/dumps/](meteor75-pro-ii/dumps/). It matched the configuration on all 134
explicit settings. The calibration in it is `-29,5,23,1`.

The pilot flew it from 2026-10-12 to 2026-11-17 and reported it "exceptional". The pilot closed
the remaining setup checks on 2026-11-17. Two checks were never done:

- The individual motor test.
- The link-loss bench test. The saved failsafe is `DROP`, but nobody saw the actual response.

Do not report these two checks as passed. Any later rate or throttle change uses a separate
OpenSpec change. The main spec is
[meteor75-pro-ii/flight-config](openspec/specs/meteor75-pro-ii/flight-config/spec.md).

## Pavo20 Pro II — out of service

**The AIO burned. The pilot reported it on 2026-11-17.** The pilot suspects a MOSFET fault on the
board. The date of the failure and the cause are not established. No log or photo exists.

The aircraft is on pause. The pilot did not like the 4S variant and can replace the board with a
3S AIO. There is no plan for this.

Do these steps before you configure a replacement board:

- Get the board target of the new board. A 3S board can use a target other than `BETAFPVG473_V3`.
- Do not paste a 4S config onto a 3S board. A config from one cell-count variant does not run
  correctly on another.
- Capture a fresh `diff all` from the new board before you paste anything.
- Calibrate the accelerometer on the airframe. The old calibration and `mcu_id` belong to the
  burned board.
- Examine the UART pads against the target of the new board. The GPS and air-unit pin conflict
  below was specific to the Cube G4.

The GPS module, the GPS Rescue procedure and the specs in `openspec/specs/pavo20-pro-ii/` still
apply to a rebuild. Treat everything that was verified on the old board as unverified on a new
one. The GPS Rescue change closed on 2026-11-17 with one task not done; see
[the archive](openspec/changes/archive/2026-11-17-configure-pavo20-gps-rescue/).

The rest of this section is the last configuration of the burned board.

BetaFPV Pavo20 Pro II **4S variant**, board target `BETAFPVG473_V3` (Cube G4 2-4S 30A AIO,
STM32G474). DJI O4 Air Unit Pro. ELRS receiver, flown with a HelloRadio V12 MAX.
Flown on both 3S and 4S packs.

Running `pavo20-pro-ii/PAVO20PRO2_ELRS_V1.txt` on Betaflight 2025.12.2. The authoritative record of
the aircraft is `pavo20-pro-ii/dumps/BTFL_cli_backup_PAVO20PRO2_20260903_BETAFPVG473_V3 -
current.txt` — where a document disagrees with that capture, the capture is right.

Wiring after the 2026-09-01 rewire:

| Signal | Pad | MCU pin |
|---|---|---|
| LED strip data | T1 | PA9 |
| SBUS from the O4 air unit (unused on ELRS) | R1 | PA10 |
| GPS module RX | T2 | PA2 |
| GPS module TX | R2 | PA3 |
| ELRS receiver | internal | PB10 / PB11 |
| DJI O4 MSP DisplayPort | internal | PC10 / PC11 |

LED strip power is soldered directly to the battery input pads, not the 5 V BEC. An external
buzzer is fitted.

GPS is a **BZGNSS BZ-181** (u-blox M10) running the **UBLOX** provider with `gps_auto_config = ON`
and `gps_ublox_use_galileo = ON`, since 2026-09-03.

It ran NMEA until then, on the belief that this module never answers a UBX `MON-VER`. **That was
false.** The belief was formed before the 2026-09-01 rewire, while the module's TX was contended on
`R1 (PA10)` with the O4 air unit's SBUS output, and it was never re-tested afterwards. Retested
2026-09-03: `MON-VER` is answered, auto-config completes, 3D fix on 10 satellites.

`gps_provider` and `gps_auto_config` both equal the 2025.12.2 firmware default and are written
explicitly in the configs anyway — see the comment there, and
`openspec/specs/pavo20-pro-ii/gps-provider/`.

**NMEA remains the recovery path, not a rejected option.** UBLOX needs the FC→module TX line alive
at every boot; NMEA needs nothing from the FC. `pavo20-pro-ii/GPS_SETUP.md` has the fallback lines
and why.

**The committed configs carry no accelerometer calibration**, deliberately, so pasting one leaves
the board's own calibration alone. A paste onto a flashed or fresh board **must** be followed by
Calibrate Accelerometer — `pavo20-pro-ii/SETUP_GUIDE.md` section 8.

## Outstanding work

### 1. GPSQR widget — parked, field-untested

`radio/WIDGETS/GPSQR/main.lua` shows the last received GPS position as a QR code scannable into
Google Maps and persists it to the SD card. The Pavo20 was the only aircraft with GPS, so the
widget has no aircraft until the Pavo20 or another GPS aircraft flies. Review record in
`radio/CODE_REVIEW.md`.

Bench-verified 2026-09-03: loads without error, the QR scans, the status word renders, and a fix
survives a radio power cycle marked `SAVED`.

The no-fix defect is fixed in the code. `hasFix()` requires at least 5 satellites from the `Sats`
sensor, and the status line shows `NO FIX (n sat)` or `NO SAT SENSOR`. The `radio/gpsqr-widget`
spec has the requirement. The fixed code has not run in the field.

Still unknown:

- **Behaviour after a real failsafe.** A clean power cycle is not the same event as telemetry
  stopping mid-stream. Confirm it holds the last fix and counts the age up rather than blanking or
  freezing on `LIVE`.
- **How far the pin is from where the quad actually lands.** The widget shows the last fix the
  radio *received*, not the resting place. Never measured. Until then no accuracy figure is quoted
  anywhere, on purpose.
- **The coordinate origin, so any zone but full-screen.** EdgeTX does not document whether a
  widget's LVGL `x`/`y` are relative to its zone or to the screen. **Until checked, use
  full-screen.** If it draws at the screen corner, every `x`/`y` in `buildUI` needs `+ w.zone.x` /
  `+ w.zone.y` — do not add that speculatively.
- **Square zones.** The square case is the one the shipped code got wrong.
- **The failed-SD-write path.** Rename `/LOGS/` on the card, run with a live fix for a minute, and
  watch for the radio stuttering.

**Accepted defect: the save file is shared across models.** `SAVE_PATH = "/LOGS/gpsqr_last.txt"` is
one file for the whole radio, so switching models shows the previous model's position marked
`SAVED`. **Decided 2026-09-03 not to fix it.** The operating rule: trust `LIVE` or an age, treat
`SAVED` as "some aircraft's last position". Reopen if the widget is ever relied on across more
than one model in a session.

### 2. Meteor75 — configs rewritten, flying, checks outstanding

On 2026-09-29 the Meteor75 was reported "way too sharp, no range for smooth turns" in Acro. A
`diff all` showed the aircraft matched no file in the repo: rate profile 0 had Center Sensitivity
1150 °/s against a 720 °/s max (a straight-line curve, expo disabled — 115 °/s at 10 % stick), and
PID profile 0 had been reset to firmware defaults, losing BetaFPV's GF 40mm tune. Both happened in
the Configurator; nothing in the repo could have noticed. Change `align-meteor75-with-aircraft`
replaced the three old configs with `M75_PRO_ELRS_V1.txt` and `M75_PRO_SBUS_V1.txt`: GF 40mm
restored verbatim, Cine / Park / Base rate profiles on CH9, `vbat_max_cell_voltage = 450` for the
LiHV packs, no `acc_calibration`. The aircraft as found is
`meteor75-pro/dumps/BTFL_cli_backup_M75_PRO_20260929_BETAFPVG473 - as found.txt`. The ELRS file was
pasted and levelled the same evening; the round-trip `diff all` (` - V1 applied`) matched it exactly,
apart from `mcu_id`, `signature`, the new `acc_calibration` and the pinned defaults `serial 0 0`,
`serial 2 64` and `serialrx_provider = CRSF`, which `diff all` never prints.

**Flown 2026-09-30**, six packs, outdoors in wind. Pilot's report: the new setup "feels very good —
much better than with 1150 degrees".

- All three CH9 positions flown, and the pilot felt the difference between them, so rate-profile
  switching works in flight. The confirmation beeps could not be heard over the radio's own sound
  effects.
- Base was used most. Cine felt "a bit underpowered" in the wind. It is not: all three profiles
  have the same throttle curve and no throttle limit, so thrust is identical. Cine rotates more
  slowly for the same stick (79 vs 122 °/s at half stick, 450 vs 720 °/s at full), so corrections
  against gusts arrive later. Expected behaviour, not a fault; recorded so it is not re-diagnosed.
- No notable oscillation, allowing for the wind. Motor temperature was not checked; the pilot
  closed that check on 2026-09-30, to be reopened only if something feels or smells wrong.
- Power loops and throttle chops on the restored dynamic idle (`30`): no complaints.
- Battery on plug-in checked by the pilot: "everything was as expected", confirming
  `vbat_max_cell_voltage = 450` detects a fresh LiHV pack.
- Angle used for take-off and landing with no levelling problems. No crash was reported, so this
  says nothing about the accelerometer fault below, which appears after impacts.

Outstanding, all by the pilot — see the change's `design.md` under *Open Questions*:

- **Curves.** Park's curve is a midpoint chosen for comparison, not a published value. If Base
  becomes the everyday profile, a softer-centred Base is a candidate — as a new versioned file.
- **SBUS variant untested.** Reproduces the factory receiver setup (UART1 / PA10). Test when the DJI
  RC is next used: Receiver tab shows CH1–CH9 as the AUX table expects, bench-arm props off.
- **Physical pads** for UART1 RX (PA10) and UART3 RX (PB11) are not recorded.

**Telemetry was off, and was enabled 2026-09-30.** The Oxbot R1 showed no `RxBt` for the Meteor75.
`feature TELEMETRY` was absent from every capture of this aircraft, the 2026-01-30 factory original
included, and at 4.5.1 the BETAFPVG473 target sets no default features, so no `RxBt`, `Curr`,
`Capa` or `FM` ever reached any radio — the V12 included. The ELRS link stats still showed, which
is what hid it. Enabled through the CLI and saved on 2026-09-30, without re-pasting the config, so
the accelerometer calibration was untouched; `RxBt` appeared on the R1 immediately.
`M75_PRO_ELRS_V1.txt` now carries `feature TELEMETRY`, and
`dumps/BTFL_cli_backup_M75_PRO_20260930_BETAFPVG473 - current.txt`, captured 2026-09-30 after the
change, matches it: the only differences are `mcu_id`, `signature`, `acc_calibration` and the
pinned defaults `serial 0 0`, `serial 2 64` and `serialrx_provider = CRSF`. Against the previous
capture (now ` - V1 applied`) it differs in exactly two lines: `feature TELEMETRY`, and
`acc_calibration` — see the table below. Requirement: `meteor75-pro/flight-config`, "The ELRS config SHALL enable Betaflight telemetry"
(`openspec/specs/meteor75-pro/flight-config/spec.md`).

**Accelerometer X axis — probable hardware fault. Angle mode cannot be trusted after a crash.**
`acc_calibration` stores the average of 400 readings taken level and still, as X, Y, Z-minus-1 g
and a done flag (`performAcclerationCalibration`, `sensors/acceleration_init.c:442-474` at 4.5.1).
On this board's ICM-42688P 1 g is 2048 counts (`accgyro_spi_icm426xx.c:204`, 16 g range):

```
acc_calibration       X                  Y              Z (minus 1 g)
factory 2026-01-30    24      0.01 g     15    0.01 g   46   0.02 g
V1 files (undated)    -12851  -6.3 g     -6    0.00 g   14   0.01 g
as found 2026-09-29   -17621  -8.6 g     -71  -0.03 g   65   0.03 g
after paste 09-29     -30382  -14.8 g    2     0.00 g   57   0.03 g
re-levelled 09-29     -21126  -10.3 g    0     0.00 g   56   0.03 g
capture 09-30         -10643  -5.2 g     1     0.00 g   53   0.03 g
```

The 09-30 row is from the capture taken after enabling telemetry. The pilot did not press
Calibrate Accelerometer. At 4.5.1 power-on calibrates only the gyro (`fc/init.c:825`); the stored
accelerometer zero is rewritten only by the Configurator button (`msp/msp.c:3285-3287`), a gimbal
mixer (`init.c:821-823`, never on a quad), or the disarmed **stick command throttle high + yaw left
+ pitch down + roll centred**, held about 50 ms (`fc/rc_controls.c:230`, `:290-292`), and it saves
itself on completion (`sensors/acceleration_init.c:468-470`). The most likely cause is that stick
command, hit by accident: the pilot habitually rotates the sticks, with the aircraft powered and
disarmed. Not proven — Betaflight logs no record of which trigger fired. The calibration it left
is usable: on 2026-09-30 the Setup tab showed the quad level on a flat surface, and the pilot
reports it flew well in Angle on the R1 the same day. No re-level was needed.

What it says about the fault: a calibration taken still can move X by at most about 1 g
(2048 counts) through tilt. This one moved it about 10,500 counts, 5 g, with Y and Z steady — the
same X-only instability. It does not meet the "after a crash" test below, since no crash preceded
it. **The habit that prevents the accidental case: do not stir the sticks with a quad powered and
disarmed.** It applies equally to the Pavo20, whose GPS Rescue takes its level reference from this
calibration.

Y and Z are healthy and consistent — Z reading 1.03 g is gravity, which also confirms the scale.
X reading 5–15 g on a stationary quad is not physical, and no board tilt could produce it (a
90° misalignment moves gravity by 1 g). Its zero jumps between levellings. The pilot reports, on
2026-09-29, that Angle mode flies wrongly after crashes and that the Setup tab sometimes shows the
quad tilted when it is level; they had been flying with the OSD horizon to compensate. Consistent
with impact damage to the X channel of the IMU. At −14.8 g the offset left 1.2 g before the 16 g
clip, so X readings were saturating.

This is not yet proven: the pilot confirmed the Sensors-tab accelerometer is live but has not
reported a tilt test per axis. **What settles it:** after the next crash, `get acc_calibration`,
then Calibrate Accelerometer, then `get acc_calibration` again. A jump of thousands of counts in X
confirms it.

Until the board is replaced: Acro is unaffected (the accelerometer does not fly Acro). After any
crash, check the Setup tab on a flat surface before flying and recalibrate if the model is not
level; do not rely on Angle for take-off or landing until that check has been done. The real fix is
a replacement flight controller — paste `M75_PRO_ELRS_V1.txt`, calibrate, and expect X within a few
hundred counts of 0, as the factory board read.


### 3. Oxbot R1 — in use on both aircraft

Second ELRS radio, on trial against the V12 MAX from 2026-09-30. It runs OXBOT OS, not EdgeTX, so
the GPSQR widget and the logical-switch alarms do not carry over. Setup, mapping and bench check are
in `radio/oxbot-r1/README.md`; the change is `openspec/changes/archive/2026-10-01-add-oxbot-r1-radio/`.

**Verified 2026-09-30:** the R1 links to both the Pavo20 and the Meteor75 with the binding phrase
entered on the radio, no receiver change. The fleet pairs by phrase only from now on.

**Observed, before the R1 was remapped:** flipping SD beeped (SD is CH8 in the R1's default
mapping), and an arm attempt on the Pavo20 failed. Indoors that is expected — the Pavo20 cannot arm
without a GPS fix (`gps_rescue_allow_arming_without_fix = OFF`, `fc/core.c:400-406`), whatever
PREARM is doing. Whether the Meteor75 also refused was not recorded.

**Done 2026-09-30:** the R1's single model remapped (CH5 SA, CH6 SB, CH7 SF, CH8 SE, CH9 SC,
CH10 SD), 250Hz, Telem Ratio 1:64, 250 mW, Model Match and Throttle Lock off; every switch checked
on the R1's *View Channels*, SE confirmed latching. **Meteor75:** Receiver tab AUX1–AUX5 all as
expected, grip test clean, armed on the bench, then flown.

**Pavo20, 2026-09-30:** Receiver tab AUX1–AUX5 as expected, AUX6 follows SD, grip test clean.
Refused to arm indoors with repeated beeps — expected without a fix — but `status` was not read.

**2026-10-01, confirmed by the pilot:** SD up refuses arming; the R1 has alarms (thresholds not
recorded); Find Drone works with a fix. Find Drone with **no** fix was left untested by choice —
see `radio/oxbot-r1/README.md` for why `Sats` should still be checked before trusting a pin.

**Flown 2026-10-01, both aircraft.** The Pavo20 armed outdoors once it had a fix — reached
quickly, up to 32 satellites — consistent with `GPS` having been its only indoor block. Pilot's
report: everything worked as expected, no problems noticed, motors not hot. A plain flight; it says
nothing about a rescue or failsafe on the R1.

## Facts that cost real time to establish

Keep these in mind before diagnosing anything similar. Each of these looked like a fault and was
not, or looked like one fault and was another.

**Center Sensitivity at or above Max Rate switches expo off.** In Actual rates, expo only scales
`MAX(0, srate*10 - rc_rate*10)` (`applyActualRates`, `fc/rc.c:209-219` at 4.5.1). When the centre
reaches the max, that term is zero and the curve is a straight line through the *centre* value at
full stick — the configured max is ignored too. The Meteor75's 1150 / 720 profile was that. The
Configurator shows the two fields side by side in °/s, which is how it got set.

**`vbat_max_cell_voltage` gates battery detection, not just the cell count.** At 4.5.1
`isVoltageFromBattery` (`sensors/battery.c:190-197`) treats a reading as a battery only if it is at
or below this value, or above 6.00 V. A 1S LiHV pack above it is *not present* — no cell count, no
warnings, no PID-profile auto-select — until it sags into range, possibly in flight. A reading
exactly equal to it counts as 2S (`battery.c:210`). The firmware default 430 and the Meteor75's old
435 both fail on a fresh 4.35 V pack; the Meteor runs 450.

**GPS and the air unit shared a pin.** The Cube G4 routes the O4's SBUS output to `RX1 (PA10)`.
The GPS module's TX had been soldered to that same pad, following BetaFPV's own GPS guide — which
is written for a *different board*. Two push-pull drivers on one net. GPS worked perfectly with the
air unit unplugged and produced bit-corrupted NMEA the moment it was connected. Diagnosed by
continuity-testing the air unit connector against R1. Full write-up in `pavo20-pro-ii/GPS_SETUP.md`.

**`GPS: connected` in `status` is meaningless on NMEA.** It reads true with the module physically
unplugged. It derives only from `gpsData.state >= GPS_STATE_CONFIGURE`, and the NMEA path advances
the state machine without needing a byte. Use a satellite count in the Configurator GPS tab, or GPS
elements appearing in the OSD.

**Betaflight omits GPS OSD elements entirely until `SENSOR_GPS` sets.** So "no GPS in the OSD" and
"GPS showing zeros" are different faults. Zeros means working, no fix.

**A trailing `profile N` line in a config does not decide the tune.**
`changePidProfileFromCellCount` in `src/main/config/config.c` at tag `2025.12.2` runs on every
battery connect while disarmed and switches to the profile whose `auto_profile_cell_count` matches
the detected cells, overriding whatever the CLI selected. Profile 0 (`O4Pro3S`) declares `3` and
profile 1 (`O4Pro4S`) declares `4`, so the pack decides. Profile 2 (`O4 Soft`) declares the STAY
value and is therefore manual-only by design. This was first diagnosed the other way round — as a
config that would strand a 4S aircraft on the 3S tune — and the source settled it. Do not refile it
as a bug.

**A setting absent from a `diff all` equals the firmware default — which does not tell you what
that value is.** `gps_auto_baud` and `rates_type` both vanished from the Pavo20 capture; `get`
showed `OFF` and `ACTUAL`, matching intent. The dangerous reading is the other one: a line dropped
from a chunked paste also disappears from the next diff and looks identical. Only `get`
distinguishes them, and it prints the allowed values too.

This is not hypothetical: `gps_provider` and `gps_auto_config` are the only two lines of
`PAVO20PRO2_ELRS_V1.txt` that do not appear in the 2026-09-03 capture, because both equal the
2025.12.2 default. They are pinned in the config anyway, precisely so a reader sees the choice.

**`get` printing a value proves a setting is settable, not that anything reads it.** `gps_auto_baud`
was recorded here as load-bearing as a *value* and inert only as a *line*. Both halves were wrong.
At 2025.12.2 the field exists in `gpsConfig_t` (`src/main/pg/gps.h`) and is settable from the CLI
(`src/main/cli/settings.c:1137`) — hence the `OFF` from `get` — but `src/main/io/gps.c` never reads
it, and the UBLOX driver baud-scans unconditionally either way. **The value is inert too.** Only
the firmware source separates a live default from a dead one; `get` cannot make that distinction
at all.

**A claim about hardware behaviour expires when the signal path it rests on changes.** "This module
never answers `MON-VER`" was true as recorded, on the wiring in place when it was recorded. The
2026-09-01 rewire moved the exact wire the claim depended on, and nobody re-tested — so it was
carried across unchanged into two configs, two documents and two spec rationales, hardening from
"not worth pursuing" into "do not set `gps_provider = UBLOX`". It survived four days and six files
before a single retest disproved it. `GPS_SETUP.md` even named the correct cause as its second
hypothesis and then dropped it. When wiring, pads or firmware change, list what was concluded under
the old arrangement and re-check it.

**Accelerometer calibration goes stale within a single aircraft** — not just between aircraft,
which is the rule everyone knows. Anything that disturbs the board invalidates it, nothing in a
config file records when it was taken, and a bad one produces no error: just a drifting horizon in
Angle mode and a wrong level reference for GPS Rescue. This is why the committed configs no longer
carry one.

**`gpspassthrough` halts the flight controller.** `serialPassthrough()` runs `while (1)`. Telemetry
stops, the Configurator drops to its Welcome screen, and only a reboot exits. It is also an unfair
test with the air unit attached, because UART4 interrupts keep firing while the scheduler is
stopped.

**"Sensor lost" on the radio after any CLI command** is Betaflight skipping the telemetry task while
the CLI is open. Not a fault.

**The buzzer is silent on USB with no battery.** Deliberate. Plug a battery in.

**An upside-down prop reads exactly like a PID oscillation** — flies, but screams above ~35%
throttle. Check prop orientation before touching the tune.

**Lookup values are matched exactly, and a rejected one can fail silently.** `failsafe_procedure`
takes `AUTO-LAND`, `DROP` or `GPS-RESCUE` — **hyphen, not underscore** (`cli/settings.c:382-384`).
The CLI compares with `strcasecmp` (`cli/cli.c:4552-4553`): case does not matter, punctuation does.
`GPS_RESCUE` is rejected. This sat in `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt` for days and would have
failed on first paste. The danger is not the error — it is that the file is a **single line with no
`batch start`**, so the rejected line scrolls past, `save` writes nothing, and the aircraft keeps
`DROP` while you believe GPS Rescue is armed. Underscores elsewhere are fine because those tables
use them (`MAX_ALT`, `RESCUE_SANITY_FS_ONLY`); the only way to know is to read the table or run
`get`, which prints the allowed values. **After any lookup `set`, read it back with `get`.**

**`profile_name` and `rateprofile_name` are capped at 8 characters.** Exceeding it aborts the whole
batch at `save` and nothing is written.

**The Configurator CLI drops lines from large pastes.** Paste in chunks. One dropped line here
produced a GPS fault that was misattributed for a long time.

**A full blackbox flash fails silently.** On the Pavo20, `blackbox_device` read `SPIFLASH` and
logging was on, but `flash_info` gave `usedSize` equal to `totalSize`, so nothing was written. No
warning shows. Erase the flash before every flight that must be logged. The Cube G4 flash is
16 MB (JEDEC `0x852018`), not the 2 MB M25P16 that `HARDWARE.md` stated until 2026-09-20.
There is no `feature BLACKBOX` at 2025.12.2.

**GPS Rescue can disarm in the air whatever `gps_rescue_sanity_checks` says.** In
`RESCUE_ATTAIN_ALT`, a climb below half the target for 10 s forces `RESCUE_LANDING`, and 10 s more
disarms (`gps_rescue_multirotor.c:434-460`, `:826-838`, at 2025.12.2). An `ap_hover_throttle`
below the real hover causes this. Measure hover on the pack in use before a rescue test.
Within 5 m of home and below 4 m, a rescue disarms on purpose (`:725-727`).

**`RESCUE_SANITY_FS_ONLY` is safer than `ON` for switch tests.** `ON` turns any sanity failure into
`RESCUE_ABORT`, which disarms (`gps_rescue_multirotor.c:834-838`). `FS_ONLY` hovers for 20 s
instead, except on hard Rx loss (`:366-375`). In a real failsafe the two are the same.

**`gps_rescue_return_alt` is inert under `MAX_ALT`.** Only the `FIXED_ALT` branch reads it
(`gps_rescue_multirotor.c:179-181`). With `gps_set_home_point_once = ON`, `maxAltitudeCm` holds
until power cycle (`:160-163`), so one high flight raises every later rescue on that battery.

**ELRS `8ch` Full-Res switch mode does not send CH10.** At ExpressLRS 3.5.6 it sends CH1–4 and
CH6–9 only, and the missing channel shows a steady 1500 with no error. `12ch Mixed` sends CH6–13
but forces CH5 to two positions. The table is in `radio/README.md`, and the rule is the
`radio/elrs-link` spec.

**`mcu_id` stays in git history.** The Pavo20 `mcu_id` is still in plain text in commit
`20b4f45`. On 2026-11-17 the pilot decided to keep the history as it is. The value is a board
serial, not a credential, and that board is now burned. Run `git grep <the id>` before you commit
a capture from an aircraft.

**Calibration in a capture is correct; calibration in a paste-able config is not.** Every file in
a `dumps/` folder keeps `acc_calibration`, because it records the board on that day. The
FireFly25 defaults file is a capture of this type. Only configs that a person pastes must omit
calibration. This closed the FireFly25 calibration item on 2026-11-17.

## Method note

Several confident diagnoses in this repo's history were wrong, and the evidence settled them: a
continuity check, a control test with the module unplugged, a `gpspassthrough` capture, and a read
of `config.c` at the exact firmware tag each overturned a plausible theory. Where a claim about
firmware behaviour matters, read the Betaflight source at the version in use and quote it —
`CLAUDE.md` lists where to look. Where a claim about the aircraft matters, measure it.
