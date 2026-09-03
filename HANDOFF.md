# Handoff — state of the repo as of 2026-09-03

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
| **Pavo20 Pro II** | Flying. Rewired 2026-09-01, configs reconciled to it 2026-09-03. Active work is here. |
| **Meteor75 Pro** | Stable, documented, no outstanding work. |
| **FireFly25** | Bare defaults capture only. Not actively worked on. |
| **Radio (V12 MAX)** | GPSQR widget bench-verified 2026-09-03. Field checks outstanding; one known defect accepted. |

## Pavo20 Pro II — current configuration

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

GPS is a **BZGNSS BZ-181** (u-blox M10) running the **NMEA** provider at a fixed **115200**, with
`gps_auto_baud` and `gps_auto_config` off. This module never answers a UBX `MON-VER`, so the UBLOX
provider cannot complete baud detection. Do not "fix" this by setting `gps_provider = UBLOX`.
`gps_auto_baud` is off by *default* on this firmware and so does not appear in the config file; the
value is load-bearing, the line was not.

**The committed configs carry no accelerometer calibration**, deliberately, so pasting one leaves
the board's own calibration alone. A paste onto a flashed or fresh board **must** be followed by
Calibrate Accelerometer — `pavo20-pro-ii/SETUP_GUIDE.md` section 8.

## Verified vs not verified

This distinction matters more than usual — these configs fly real hardware.

**Verified on the aircraft:**

- ELRS config applied, saved, and flown (2026-09-02, on 4S)
- The rewire is in saved config, not just in a file — confirmed against the 2026-09-03 capture
- GPS acquires and reports data with the O4 air unit connected — the original fault is fixed
- LED strip works on its new pin (PA9); buzzer works on battery
- Motors, arming, modes all behaving

**NOT verified — treat as unknown:**

- **First outdoor cold-start GPS fix.** The last capture showed 4 satellites, no fix, and empty
  ephemeris. Whether it achieves and holds a 3D fix in the field has not been confirmed.
- **GPS Rescue.** Configured in a file but never applied and never tested. See below.
- **The SBUS config.** `PAVO20PRO2_SBUS_V1.txt` has never been pasted or flown. It was edited on
  2026-09-03 alongside the ELRS config because it carried the same stale calibration; that changed
  nothing about its status.
- **The reconciled configs round-tripping.** The 2026-09-03 edits were verified by comparison
  against the capture, with no aircraft involved — every `set` line in `PAVO20PRO2_ELRS_V1.txt` now
  matches the aircraft except the deliberately absent `acc_calibration`. Nobody has pasted the
  edited file and re-captured. The residual risk is an edit wrong in a way only a paste reveals,
  such as a line the CLI rejects. Next time it is pasted for any reason, take a fresh `diff all`
  and compare.
- **OSD altitude after arming.** It reads ground elevation (~124 m) while disarmed, which is
  expected. That it zeroes on arming was explained from source but not observed in flight.
- **GPS telemetry reaching the radio — almost certainly working, one check outstanding.** The
  GPSQR widget displayed a real position while bound to the Pavo20, which it cannot do unless the
  `GPS` sensor is in the CRSF stream carrying non-zero coordinates. The caveat is that the widget's
  save file is shared across models, so a `SAVED` position on the Pavo model may belong to another
  aircraft. Five seconds to settle: bind to the Pavo outdoors and check the status word reads
  `LIVE` or an age.

## Outstanding work

### 1. GPS Rescue — configured, untested, do not trust yet

`pavo20-pro-ii/PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt` is written but has not been pasted.

The user chose GPS Rescue over DROP after being told the trade-offs. It is the only failsafe that
keeps motors running under power, so its failure mode is a flyaway rather than a broken quad.
`pavo20-pro-ii/FAILSAFE.md` has the full testing procedure — switch-testing in a large open field
at 40–60 m before it is trusted as a failsafe.

Two settings still need values. They are lookups whose options vary by firmware version, so read
them off the aircraft rather than guessing:

```
get gps_rescue_alt_mode
get gps_rescue_sanity_checks
```

Intent: the "max altitude reached this flight" mode, and sanity checks **on**.

GPS Rescue takes its level reference from the accelerometer calibration, so do not test it on a
board that has been pasted to without a re-level.

### 2. GPSQR widget — bench-verified, field-untested

`radio/WIDGETS/GPSQR/main.lua` shows the last received GPS position as a QR code scannable into
Google Maps and persists it to the SD card. It is the backup for GPS Rescue, which on the Pavo20
has never been tested. Review record in `radio/CODE_REVIEW.md`.

Bench-verified 2026-09-03: loads without error, the QR scans, the status word renders, and a fix
survives a radio power cycle marked `SAVED`.

Still unknown:

- **Behaviour after a real failsafe.** A clean power cycle is not the same event as telemetry
  stopping mid-stream. Confirm it holds the last fix and counts the age up rather than blanking or
  freezing on `LIVE`. Props off for the first pass, per `pavo20-pro-ii/FAILSAFE.md`.
- **How far the pin is from where the quad actually lands.** The widget shows the last fix the
  radio *received*, not the resting place. Never measured. Land normally, pace out the error, write
  the number down. Until then no accuracy figure is quoted anywhere, on purpose.
- **The coordinate origin, so any zone but full-screen.** EdgeTX does not document whether a
  widget's LVGL `x`/`y` are relative to its zone or to the screen. A full-screen zone cannot tell
  you, since the origin is `0, 0` either way. **Until checked, use full-screen.** If it draws at
  the screen corner, every `x`/`y` in `buildUI` needs `+ w.zone.x` / `+ w.zone.y` — do not add that
  speculatively, it breaks the full-screen case if the current behaviour is already right.
- **Square zones.** The square case is the one the shipped code got wrong, so it is the one worth
  checking.
- **The failed-SD-write path.** Rename `/LOGS/` on the card, run with a live fix for a minute, and
  watch for the radio stuttering.

**Accepted defect: the save file is shared across models.** `SAVE_PATH = "/LOGS/gpsqr_last.txt"` is
one file for the whole radio, so switching models shows the previous model's position marked
`SAVED` with nothing saying which aircraft it belongs to. For a tool whose only job is telling you
where to walk, that is a wrong-answer-with-confidence failure, and worse than showing nothing. A
per-model path would fix it. **Decided 2026-09-03 not to do it.** The operating rule instead: trust
`LIVE` or an age, treat `SAVED` as "some aircraft's last position". Written up in
`radio/README.md`. Reopen if the widget is ever relied on across more than one model in a session.

### 3. Decide about the MCU ID in git history

`mcu_id` was redacted from `pavo20-pro-ii/HARDWARE.md` on 2026-09-03, but it was committed in plain
text in `20b4f45` and is still reachable there. The working tree is clean.

It is a per-board hardware serial, not a credential: it identifies this flight controller and
cannot be used to reach it. The options are to leave it, or to rewrite history — which on a public
repo means force-pushing and breaking every clone and fork. Leaving it is defensible. The thing not
to do is assume it is gone because the current files look clean.

Keep the habit that caught it: `git grep <the id>` across tracked files before committing anything
captured off the aircraft.

### 4. Optional: retest the UBLOX provider

The FC→module TX path now runs through a new solder joint on T2. UBLOX failed before the rewire,
but that was never cleanly isolated from the pin contention. Worth one bench retest — a real
version string in `status` instead of `version = unknown` means it worked. NMEA is entirely
sufficient if it does not.

### 5. Known gap: the rest of the fleet still commits calibration

`M75_hello_radio_v12.txt`, `M75_PRO_CLAUDE_CODE_V1.txt`, `M75_PRO_RADIOMASTER_POCKET_V1.txt` and
the FireFly25 defaults capture all carry `acc_calibration` — the defect the Pavo20 configs were
just cleaned of. The Meteor75 is recorded as stable and was not touched on the strength of a
finding from another aircraft. Promoting the requirement to a fleet-wide capability is the natural
follow-up if the Pavo20 change proves out.

### 6. Delete the superseded folders

`D:\Code\Meteor75`, `D:\Code\FireFly25` and `D:\Code\Pavo20Pro2` were copied into this repo and
left in place as a fallback. Remove them once this repo is confirmed good. The original
`GPSQR_widget.zip` in `Downloads/` can go at the same time.

## Facts that cost real time to establish

Keep these in mind before diagnosing anything similar. Each of these looked like a fault and was
not, or looked like one fault and was another.

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

**`profile_name` and `rateprofile_name` are capped at 8 characters.** Exceeding it aborts the whole
batch at `save` and nothing is written.

**The Configurator CLI drops lines from large pastes.** Paste in chunks. One dropped line here
produced a GPS fault that was misattributed for a long time.

## Method note

Several confident diagnoses in this repo's history were wrong, and the evidence settled them: a
continuity check, a control test with the module unplugged, a `gpspassthrough` capture, and a read
of `config.c` at the exact firmware tag each overturned a plausible theory. Where a claim about
firmware behaviour matters, read the Betaflight source at the version in use and quote it —
`CLAUDE.md` lists where to look. Where a claim about the aircraft matters, measure it.
