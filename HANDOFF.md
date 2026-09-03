# Handoff — state of the repo as of 2026-09-03

Written so a session with no prior context can pick this up. Read this, then
`docs/betaflight-reference.md`, then the folder for whichever aircraft you are working on.

## Where things stand

| Aircraft | Status |
|---|---|
| **Pavo20 Pro II** | Flying. Rewired and reconfigured 2026-09-01. Active work is here. |
| **Meteor75 Pro** | Stable, documented, no outstanding work. |
| **FireFly25** | Bare defaults capture only. Not actively worked on. |
| **Radio (V12 MAX)** | GPSQR recovery widget added 2026-09-03, reviewed and fixed. Bench-verified; **field-untested**, and it has one known defect (below). |

## Pavo20 Pro II — current configuration

BetaFPV Pavo20 Pro II **4S variant**, board target `BETAFPVG473_V3` (Cube G4 2-4S 30A AIO,
STM32G474). DJI O4 Air Unit Pro. ELRS receiver, flown with a HelloRadio V12 MAX.
Flown on both 3S and 4S packs.

Running `pavo20-pro-ii/PAVO20PRO2_ELRS_V1.txt` on Betaflight 2025.12.2.

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

## Verified vs not verified

This distinction matters more than usual — these configs fly real hardware.

**Verified on the aircraft:**

- ELRS config applied, saved, and flown (2026-09-02, on 4S)
- **The rewire is in saved config, not just in a file.** The 2026-09-03 `diff all` shows
  `resource LED_STRIP 1 A09`, `timer A09 AF6`, `dma pin A09 8`, `resource SERIAL_TX 1 NONE`,
  and `serial UART1 0` / `UART2 2` / `UART3 64`. GPS is on UART2 and off the O4's SBUS pin.
- `gps_auto_baud = OFF` and `rates_type = ACTUAL` confirmed by `get` on 2026-09-03. Both are
  absent from the dump because they equal the firmware default, not because a paste dropped them
- GPS acquires and reports data with the O4 air unit connected — the original fault is fixed
- LED strip works on its new pin (PA9)
- Buzzer works on battery
- Motors, arming, modes all behaving

**NOT verified — treat as unknown:**

- **First outdoor cold-start GPS fix.** The last capture showed 4 satellites, no fix, and empty
  ephemeris. Whether it achieves and holds a 3D fix in the field has not been confirmed.
- **GPS Rescue.** Configured in a file but **never applied and never tested**. See below.
- **The SBUS config.** `PAVO20PRO2_SBUS_V1.txt` has never been pasted or flown.
- **OSD altitude after arming.** It reads ground elevation (~124 m) while disarmed, which is
  expected. That it zeroes on arming was explained from source but not observed in flight.
- **GPS telemetry reaching the radio — almost certainly working, one check outstanding.** The
  GPSQR widget displayed a real position while bound to the Pavo20, which it cannot do unless the
  `GPS` sensor is in the CRSF stream carrying non-zero coordinates. **The caveat:** the widget's
  save file `/LOGS/gpsqr_last.txt` is one file for the whole radio, not per model. A position
  restored from a previous FireFly25 flight would be displayed on the Pavo20 model too, marked
  `SAVED`, and would look identical to the Pavo working. If the status read `LIVE` or an age, this
  is confirmed. If it read `SAVED`, it proves nothing. Five seconds to settle: bind to the Pavo
  outdoors and check the status word.
- **The GPSQR widget itself.** Installed and working. See below.

## Outstanding work

### 1. Fresh `diff all` baseline — done 2026-09-03

`dumps/BTFL_cli_backup_PAVO20PRO2_20260903_BETAFPVG473_V3 - current.txt`, captured from the flying
aircraft, `mcu_id` redacted. The old capture was retitled ` - pre-rewire` so ` - current` keeps
meaning "this is what is flying".

**What it turned up: `PAVO20PRO2_ELRS_V1.txt` no longer matches the aircraft.** Three differences,
none of them a fault, all of them making the committed config a poor thing to re-paste:

- **`acc_calibration`** is `-66,3,-68,1` in the file, `-37,-87,-45,1` on the aircraft. The aircraft
  value is the post-rewire re-level and is the authoritative one. `acc_trim_pitch`/`acc_trim_roll`
  were cleared to default by the same re-level and are still set in the file.
- **The OSD layout was rearranged.** Eight elements moved — `gps_sats`, `home_dist`, `gps_speed`,
  `gps_lat`, `gps_lon`, `altitude`, `core_temp`, `sys_vtx_temp`. All eight still have profile bit 1
  set, so nothing is hidden; the file just describes a layout that is no longer on the aircraft.
- **Profile selection.** The file ends selecting `profile 0` (`O4Pro3S`) and `rateprofile 0`
  (`Cine`); the aircraft is on `profile 1` (`O4Pro4S`) and `rateprofile 1` (`Base`), which is
  correct for the 4S packs it is being flown on. Re-pasting the file would silently move it to the
  3S tune.

Two lines in the file are simply redundant — `set gps_auto_baud = OFF` and `set rates_type = ACTUAL`
both match the firmware default, confirmed by `get` on 2026-09-03.

Reconciling the file with the aircraft is its own piece of work and has not been done.

### 2. GPS Rescue — configured, untested, do not trust yet

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

### 3. Seed OpenSpec

Seeded. `openspec/specs/radio/gpsqr-widget/spec.md` is the repo's first spec, 7 requirements,
archived from `add-gpsqr-radio-widget` on 2026-09-03. The path establishes a `radio/` vs
per-aircraft split.

Still wanted on the aircraft side: the GPS/SBUS pin constraint. It is a rule that outlived the
change that discovered it and would bite again on any rebuild.

### 4. Optional: retest the UBLOX provider

The FC→module TX path now runs through a new solder joint on T2. UBLOX failed before the rewire,
but that was never cleanly isolated from the pin contention. Worth one bench retest — a real
version string in `status` instead of `version = unknown` means it worked. NMEA is entirely
sufficient if it does not.

### 5. GPSQR widget — installed and working, field-untested

`radio/WIDGETS/GPSQR/main.lua` is an EdgeTX widget that shows the last received GPS position as a
QR code scannable straight into Google Maps, and persists it to the SD card across a radio power
cycle. It exists because GPS Rescue can fail and, on the Pavo20, has never been tested — this is
the backup for the backup.

It was committed as shipped (`a3b2c6d`) and then fixed (`453447c`); `git diff` between the two is
the whole review. The most serious finding: the QR code was drawn with no colours set, so both
foreground and background fell back to theme variables and could render dark-on-dark. Full write-up
in `radio/CODE_REVIEW.md`.

**Verified on the radio, 2026-09-03 (bench):**

- It loads and runs, no Lua error
- The QR scans with a phone and opens the Maps pin
- The status word (`LIVE` / `SAVED` / age) renders alongside the code
- A fix survives a radio power cycle and comes back marked `SAVED`

**NOT verified — treat as unknown:**

- **Behaviour after a real failsafe.** A clean power cycle is not the same event as telemetry
  stopping mid-stream. Confirm the widget holds the last fix and starts counting the age up rather
  than blanking or freezing on `LIVE`. Props off on the bench for the first pass, per
  `pavo20-pro-ii/FAILSAFE.md`.
- **How far the pin is from where the quad actually lands.** The widget shows the last fix *the
  radio received* — the last one transmitted before the link died — not the resting place. The gap
  has never been measured. Land normally, note the coordinates, pace out the error, write the
  number down. Until then no accuracy figure is quoted anywhere, on purpose.
- **That the Pavo20 position was live, not a stale FireFly25 fix.** See the telemetry bullet
  above. The save file is shared across models, so `SAVED` on the Pavo model may be the FireFly's
  last position. Check the status word reads `LIVE` or an age.
- **The coordinate origin, so any zone but full-screen.** EdgeTX does not document whether a
  widget's LVGL `x`/`y` are relative to its zone or to the screen, and its own example implies the
  screen. A full-screen zone cannot tell you — the origin is `0, 0` either way, so both readings
  agree. Put it in a half-screen zone and look at where the QR lands. **Until then, use
  full-screen.** If it draws at the screen corner, every `x`/`y` in `buildUI` needs `+ w.zone.x` /
  `+ w.zone.y`. Do not add that speculatively — it breaks the full-screen case if the current
  behaviour is already right.
- **Square zones.** The status word was seen in the zone actually in use, which is not square. The
  square case is the one the shipped code got wrong, so it is the one worth checking.
- **The failed-SD-write path.** The bench install had a working `/LOGS/`, which exercises the
  success path. Rename `/LOGS/` on the card, run with a live fix for a minute, and watch for the
  radio stuttering.
- **Whether the colour fix was a repair or insurance.** Both versions have now scanned — but on
  *different themes*, so there is still no controlled comparison. The shipped version scanned on
  the theme in use before the reinstall; the fixed version scans on the theme the radio reset to.
  Neither has been observed to fail. What this does establish is that on at least one theme the
  EdgeTX defaults had enough contrast, so the fix is insurance on that theme rather than a repair.
  It stays worth having precisely because the theme changed by itself during the reinstall — the
  variable the shipped code depended on is one that moves without being asked.

- **Known defect, deliberately not being fixed: the save file is shared across models.**
  `SAVE_PATH = "/LOGS/gpsqr_last.txt"` is one file for the whole radio. Switch models and the
  widget shows the previous model's last position, marked `SAVED`, with nothing indicating it
  belongs to a different aircraft. For a tool whose entire job is telling you where to walk, that
  is a wrong-answer-with-confidence failure mode, and it is worse than showing nothing. A per-model
  path — the model name in the filename — would fix it.

  **Decided on 2026-09-03 not to do that**, in favour of capturing the Pavo20 baseline first. The
  interim mitigation stands and is the operating rule until someone revisits it: trust `LIVE` or an
  age, and treat `SAVED` as "some aircraft's last position" rather than this one's. It is written up
  in `radio/README.md`. Reopen this if the widget is ever relied on across more than one model in a
  session.

The original `GPSQR_widget.zip` is still in `Downloads/`. The committed copy is confirmed working,
so it can go whenever.

### 6. The MCU ID is still in git history

`mcu_id` was redacted out of `pavo20-pro-ii/HARDWARE.md` on 2026-09-03, but it was committed in
plain text in `20b4f45` and is still reachable there. The working tree is clean — `git grep` finds
nothing — and every dump in `dumps/` was redacted before it landed.

Whether that is worth acting on is a judgement call nobody has made yet. It is a per-board hardware
serial, not a credential: it identifies this flight controller and cannot be used to reach it. The
options are to leave it, or to rewrite history — which on a public repo means force-pushing and
breaking every existing clone and any fork. Leaving it is defensible. The thing not to do is assume
it is gone because the current files look clean.

Worth keeping the habit that caught it: `git grep <the id>` across tracked files before committing
anything captured off the aircraft.

### 7. Delete the superseded folders

`D:\Code\Meteor75`, `D:\Code\FireFly25` and `D:\Code\Pavo20Pro2` were copied into this repo and
left in place as a fallback. Remove them once this repo is confirmed good.

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

Several confident diagnoses in this repo's history were wrong, and the hardware settled them:
a continuity check, a control test with the module unplugged, and a `gpspassthrough` capture each
overturned a plausible software theory. Where a claim about firmware behaviour matters, read the
Betaflight source at the version in use and quote it — `CLAUDE.md` lists where to look. Where a
claim about the aircraft matters, measure it.
