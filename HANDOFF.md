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
| **Pavo20 Pro II** | Flying. Rewired 2026-09-01; moved to the UBLOX GPS provider 2026-09-03. Active work is here. |
| **Meteor75 Pro** | Configs rewritten 2026-09-29 after the aircraft was found to match no committed file. Flown 2026-09-30, six packs, pilot reports it much better. SBUS variant untested; accelerometer suspect. |
| **FireFly25** | Bare defaults capture only. Not actively worked on. |
| **Radio (V12 MAX)** | GPSQR widget bench-verified 2026-09-03. Field checks outstanding; two known defects, one accepted, one open. |

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

## Verified vs not verified

This distinction matters more than usual — these configs fly real hardware.

**Verified on the aircraft:**

- ELRS config applied, saved, and flown (2026-09-02, on 4S)
- The rewire is in saved config, not just in a file — confirmed against the 2026-09-03 capture
- GPS acquires and reports data with the O4 air unit connected — the original fault is fixed
- UBLOX provider works (2026-09-03): `MON-VER` answered, auto-config completed
- Outdoor 3D fix, 10 satellites, correct position (2026-09-03). Stationary, partial sky
- `PAVO20PRO2_ELRS_V1.txt` round-trips: pasted and re-captured 2026-09-03, every `set` line and
  every `resource` / `timer` / `dma` / `feature` / `serial` / `aux` directive matched, with
  `acc_calibration` on the board and absent from the file as designed
- LED strip works on its new pin (PA9); buzzer works on battery
- Motors, arming, modes all behaving

**NOT verified — treat as unknown:**

- **GPS fix quality in flight.** The 2026-09-03 fix was stationary, on a balcony, under partial
  sky. Whether it holds a fix while moving, in open field, with motors running and the O4
  transmitting, is unconfirmed. Do not read the balcony result as clearing GPS Rescue.
- **GPS Rescue.** Block 1 (tuning) is pasted; block 2 (the arming line) is not, so the aircraft
  is still on `DROP`. One field attempt exists, on 2026-09-03, and it produced no log — nothing is
  known about whether a rescue can fly this aircraft. See below.
- **The SBUS config.** `PAVO20PRO2_SBUS_V1.txt` has never been pasted or flown. It was edited on
  2026-09-03 alongside the ELRS config because it carried the same stale calibration; that changed
  nothing about its status.
- **OSD altitude after arming.** It reads ground elevation (~124 m) while disarmed, which is
  expected. That it zeroes on arming was explained from source but not observed in flight.
- **GPS telemetry reaching the radio.** The widget has displayed a real position while bound to
  the Pavo20, which needs the `GPS` sensor in the CRSF stream. `/LOGS/gpsqr_last.txt` has since
  been deleted, so a `SAVED` position can no longer be another model's — any position the widget
  now shows on this model is this model's. Confirm the status word reads `LIVE` or an age once,
  and this is closed.

## Outstanding work

### 1. GPS Rescue — configured, untested, do not trust yet

The config is now **two files**, split 2026-09-03 because the halves carry different risk:

- `pavo20-pro-ii/PAVO20PRO2_GPS_RESCUE_TUNING.txt` — the rescue parameters. Touches no failsafe
  setting. **Safe to paste now, and should be pasted before any switch test** — an unconfigured
  board runs the firmware defaults, and `ascend_rate` defaults to `750` cm/s, a 7.5 m/s climb
  demand this airframe cannot meet.
- `pavo20-pro-ii/PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt` — one line, `failsafe_procedure = GPS-RESCUE`.
  **Not to be pasted until the switch test in `FAILSAFE.md` has passed.**

**Block 1 is pasted and verified (2026-09-03); block 2 is not.** A `diff` returned the five
`gps_rescue_*` lines that differ from default — `ascend_rate`, `descend_rate`, `ground_speed`,
`descent_dist`, `return_alt` — and correctly omitted the six that equal it. `failsafe_procedure` is
absent, so it remains at the 2025.12.2 default of `DROP_IT` (`src/main/flight/failsafe.c:78`): the
aircraft cuts motors and falls on signal loss. That is the intended state until the rescue is
proven.

The user chose GPS Rescue over DROP after being told the trade-offs. It is the only failsafe that
keeps motors running under power, so its failure mode is a flyaway rather than a broken quad.
`pavo20-pro-ii/FAILSAFE.md` has the full testing procedure — switch-testing in a large open field
at 40–60 m before it is trusted as a failsafe.

**Resolved 2026-09-03: the CH10 return-to-home switch now reaches Betaflight.** AUX 6 flips on the
Receiver tab, and `aux 6 46 5 1700 2100 0 0` is applied and confirmed in the saved config (GPS
Rescue is permanent box ID 46).

The cause was the ELRS switch mode. The radio runs `333Hz Full`, a Full-Resolution rate, and was
set to Switch Mode **`8ch`**, which at ExpressLRS 3.5.6 packs only `channelData[0..3]` and
`channelData[5..8]` — CH1–4 and CH6–9. CH10 was never transmitted. Settled on **`12ch Mixed`**,
which alternates the high group between `channelData[5..8]` and `channelData[9..12]`: CH1–4 stay at
the full 333Hz, CH5 stays a 1-bit every-packet channel, and CH6–13 arrive at ~166Hz. `16ch Rate/2`
was tried first and also worked, but it halves the stick rate as well and buys only CH14–16, which
this aircraft does not use. Per-mode channel map, read off `src/lib/OTA/OTA.cpp` at tag 3.5.6, is
in `radio/README.md` under *What each Full-Res switch mode actually transmits*.

**`12ch Mixed` forces CH5 to two positions**, because the receiver rebuilds it with
`channelData[4] = BIT_to_CRSF(ota8->rc.ch4)` (`UnpackChannelData8ch`, the `else` branch). That is
safe here and was checked: channel 0 is used by `aux 0 0 0 1700 2100` — ARM — and by nothing else.
Every other `aux` and both `adjrange` lines sit on channels 1–4. **Do not put a 3-position or
analogue source on CH5 while this mode is set**; it will collapse to two states with no error.

**Ruled out by measurement along the way, so do not re-check:** the EdgeTX mixer (channel monitor
showed CH10 swinging −100/+100), the module channel range (CH1–CH16), and `max_aux_channels`
(reads `14`, so `rxChannelCount = MIN(14 + 4, 16) = 16`).

**The config file is now complete.** Both remaining lookups were read off the aircraft on
2026-09-03 and both already held the right value — `gps_rescue_alt_mode = MAX_ALT` and
`gps_rescue_sanity_checks = RESCUE_SANITY_FS_ONLY`, each the 2025.12.2 firmware default, now pinned
explicitly in `PAVO20PRO2_GPS_RESCUE_TUNING.txt`.

**First field trigger, 2026-09-03: the quad disarmed and dropped.**

*First diagnosis, and it was wrong — kept because the branch it describes is real and will be
mistaken for a fault the next time someone triggers close in.* Within 5 m of home *and* below 4 m
altitude a rescue hits `RESCUE_ABORT` (`gps_rescue_multirotor.c:725-727`; the 4 m is
`isBelowLandingAltitude()` against `ap_landing_altitude_m`, default `4`), which disarms
deliberately and sets `ARMING_DISABLED_ARM_SWITCH`, so the arm switch must be cycled to re-arm.
That is correct behaviour, not a fault — but it is not what happened here.

**Corrected: the drop was NOT the close-range abort.** It was inferred from an earlier remark
about testing "close in" and never checked against what was actually flown. The attempt was at
**20–30 m with ~26 satellites**, well beyond both the 5 m abort and `gps_rescue_min_start_dist`,
so it took the normal rescue path and still came down.

**What the attempt did prove:** the switch reaches the rescue state machine; **home was set**,
since a missing home point takes the `RESCUE_NO_HOME_POINT` branch which under `FS_ONLY` hovers for
20 s rather than disarming; and GPS had a fix with ≥8 sats, since `allow_arming_without_fix = OFF`
with `min_sats = 8` would otherwise have blocked arming (`fc/core.c:400-407`). Prerequisites 1 and
2 in `FAILSAFE.md` are effectively cleared.

**What it did not prove, and cannot:** anything about whether the rescue can fly this aircraft.
Nothing was logged, so the phase, the failure code, and whether the motors stopped in the air or on
impact are all unrecoverable from recollection, and each points at a different cause. See the flash
note below — part of it may yet be recoverable from the chip.

**Why nothing was logged — established on the aircraft 2026-09-20.** Not a missing feature flag.
`blackbox_device` reads `SPIFLASH`, and there is no `feature BLACKBOX` at 2025.12.2 to be missing:
it appears in none of the three lists `feature` prints, the signature of a feature removed from the
build. **Logging was enabled the whole time.** The flash was simply **full** — `flash_info` returns
`usedSize` equal to `totalSize` — so there was nowhere to write. Erase before every attempt. This
failure is completely silent: nothing warns you, and you land believing you have a log.

**The flash is 16 MB, not 2 MB.** `HARDWARE.md` called it an M25P16 on SPI3 until 2026-09-20.
`flash_info` reports `totalSize=16777216` and JEDEC `0x852018` — a different manufacturer and
eight times the capacity. Any sizing argument made against 2 MB was wrong by that factor.

**Unread, and worth reading before it is destroyed:** the flash is full, so it holds logs from
earlier flights. Whether the newest covers 2026-09-03 is unknown. Download it before erasing — even
with `debug_mode` on `GYRO_FILTERED` and no `RTH` fields, an altitude and motor-output trace would
distinguish a steady sink from a clean cutoff, which is exactly the question above.

**Leading hypothesis, unconfirmed:** `ap_hover_throttle` was at the `1275` default while this
airframe hovers near 34% (`1340`). At rescue onset the integrator is reset and target altitude
equals current altitude, so commanded throttle is essentially that value
(`autopilot_multirotor.c:195-205`) — below hover, so it sinks. Falling short of the commanded climb
is then itself a failure that **ignores `gps_rescue_sanity_checks`**: `RESCUE_ATTAIN_ALT` ticks a
counter once per second when achieved climb is under half the target, forces `RESCUE_LANDING` at
ten seconds, and disarms after another ten (`gps_rescue_multirotor.c:434-460`, `:826-838`). That
ends in motors stopping, which matches what was seen.

**Next attempt is the pilot's and is outside the change `configure-pavo20-gps-rescue`.** Trigger
beyond `gps_rescue_min_start_dist` — 25–30 m — with the hover throttle measured and the log
running. Bands tabulated in `FAILSAFE.md` under *Where you can and cannot trigger a rescue*.

Two source findings came out of setting those, both of which corrected this repo:

- **`gps_rescue_return_alt` is inert under `MAX_ALT`.** It is read only in the `FIXED_ALT` branch
  (`gps_rescue_multirotor.c:179-181`); `MAX_ALT` computes `maxAltitudeCm + initialClimbCm`
  (line 186-189). And because `gps_set_home_point_once = ON`, `maxAltitudeCm` is **not** reset on
  disarm — "if set_home_point_once is true, hold maxAlt until power cycled" (line 160-163) — so the
  return altitude carries across arms just as home position does. A 60 m pack followed by a low
  cruise gives a 70 m rescue climb.
- **`RESCUE_SANITY_FS_ONLY` is safer than `ON` for switch testing, not weaker.** `ON` turns any
  sanity failure into `RESCUE_ABORT`, which disarms (line 834-838) — during a switch test the quad
  falls. `FS_ONLY` aborts only on hard Rx loss and otherwise gives 20 s of hover to recover
  (line 366-375, comment at line 214). During a real failsafe the two are identical, because a real
  failsafe *is* hard Rx loss. `FAILSAFE.md` previously said to use `ON`; that has been corrected.

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

**Open defect, found 2026-09-03: a position with no fix is displayed and saved as though real.**
`hasFix()` in `main.lua` guards only against coordinates of `0, 0`. That was the whole no-fix
signature under NMEA. Under UBLOX it is not: Betaflight assigns `gpsSol.llh` from NAV-PVT
unconditionally and records fix validity separately (`src/main/io/gps.c:2244-2256`), and
`crsfFrameGps()` transmits those coordinates with no fix check of its own
(`src/main/telemetry/crsf.c`). So a receiver with no fix sends the radio plausible, non-zero,
entirely wrong coordinates — observed as `14.786703, -7.396605`, a point in Mali, while the
aircraft sat indoors with 3 satellites and `3D Fix` false. The widget displayed it and wrote it to
the SD card.

The fix direction is known: the same CRSF frame carries `gpsSol.numSat` as its final byte, so a
satellite count does reach the radio. Which EdgeTX sensor exposes it on the V12 MAX has not been
checked, and must not be guessed — there is no interpreter or emulator in this repo. Full entry in
`radio/CODE_REVIEW.md`.

**Accepted defect: the save file is shared across models.** `SAVE_PATH = "/LOGS/gpsqr_last.txt"` is
one file for the whole radio, so switching models shows the previous model's position marked
`SAVED` with nothing saying which aircraft it belongs to. For a tool whose only job is telling you
where to walk, that is a wrong-answer-with-confidence failure, and worse than showing nothing. A
per-model path would fix it. **Decided 2026-09-03 not to do it.** The operating rule instead: trust
`LIVE` or an age, treat `SAVED` as "some aircraft's last position". Written up in
`radio/README.md`. Reopen if the widget is ever relied on across more than one model in a session.

### 3. Meteor75 — configs rewritten, flying, checks outstanding

On 2026-09-29 the Meteor75 was reported "way too sharp, no range for smooth turns" in Acro. A
`diff all` showed the aircraft matched no file in the repo: rate profile 0 had Center Sensitivity
1150 °/s against a 720 °/s max (a straight-line curve, expo disabled — 115 °/s at 10 % stick), and
PID profile 0 had been reset to firmware defaults, losing BetaFPV's GF 40mm tune. Both happened in
the Configurator; nothing in the repo could have noticed. Change `align-meteor75-with-aircraft`
replaced the three old configs with `M75_PRO_ELRS_V1.txt` and `M75_PRO_SBUS_V1.txt`: GF 40mm
restored verbatim, Cine / Park / Base rate profiles on CH9, `vbat_max_cell_voltage = 450` for the
LiHV packs, no `acc_calibration`. The aircraft as found is
`meteor75-pro/dumps/BTFL_cli_backup_M75_PRO_20260929_BETAFPVG473 - as found.txt`. The ELRS file was
pasted and levelled the same evening; the round-trip `diff all` (` - current`) matched it exactly,
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
```

Y and Z are healthy and consistent — Z reading 1.03 g is gravity, which also confirms the scale.
X reading 6–15 g on a stationary quad is not physical, and no board tilt could produce it (a
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

### 4. Decide about the MCU ID in git history

`mcu_id` was redacted from `pavo20-pro-ii/HARDWARE.md` on 2026-09-03, but it was committed in plain
text in `20b4f45` and is still reachable there. The working tree is clean.

It is a per-board hardware serial, not a credential: it identifies this flight controller and
cannot be used to reach it. The options are to leave it, or to rewrite history — which on a public
repo means force-pushing and breaking every clone and fork. Leaving it is defensible. The thing not
to do is assume it is gone because the current files look clean.

Keep the habit that caught it: `git grep <the id>` across tracked files before committing anything
captured off the aircraft.

### 5. Known gap: the FireFly25 still commits calibration

The FireFly25 defaults capture carries `acc_calibration` — the defect the Pavo20 configs were
cleaned of on 2026-09-03 and the Meteor75 configs on 2026-09-29. The Meteor75 now has its own
`meteor75-pro/flight-config` spec with the same rule. Promoting it to a fleet-wide capability is
the natural follow-up once both aircraft have flown on their new configs.

### 6. Delete the superseded folders

`D:\Code\Meteor75`, `D:\Code\FireFly25` and `D:\Code\Pavo20Pro2` were copied into this repo and
left in place as a fallback. Remove them once this repo is confirmed good. The original
`GPSQR_widget.zip` in `Downloads/` can go at the same time.

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

## Method note

Several confident diagnoses in this repo's history were wrong, and the evidence settled them: a
continuity check, a control test with the module unplugged, a `gpspassthrough` capture, and a read
of `config.c` at the exact firmware tag each overturned a plausible theory. Where a claim about
firmware behaviour matters, read the Betaflight source at the version in use and quote it —
`CLAUDE.md` lists where to look. Where a claim about the aircraft matters, measure it.
