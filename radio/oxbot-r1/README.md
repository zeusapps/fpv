# Oxbot R1

10-channel radio with a built-in 500 mW ELRS 2.4 GHz module. It runs **OXBOT OS, not EdgeTX**: a
touchscreen system with no Lua, no logical switches and no mixer screen. The GPSQR widget, the
EdgeTX alarms and the ELRS Lua script paths in `../README.md` do not apply to it.

Being trialled against the V12 MAX from 2026-09-30. Flies the Pavo20 Pro II and the Meteor75 Pro.
**Both aircraft bench-checked (2026-09-30) and flown on it (2026-10-01)**
— see *What is not verified* at the bottom.

Menu names below are from the Oxbot R1 Quick Start Guide
(`store-fnms1h2bjh.mybigcommerce.com/product_images/oxbot_r1_rc/manual/Oxbot%20R1_QSG_en.html`,
read 2026-09-30). Swipe up on the home screen for **Quick Settings**; **System Settings** is at the
top of that panel. Swipe left for **Model Selection**.

## Controls

| Control | Where | Type |
|---|---|---|
| SA | top left | 2-position toggle |
| SB | top left | 3-position toggle |
| SC | top right | 3-position toggle |
| SD | top right | 2-position toggle |
| SE | rear paddle | 2-position, latching |
| SF | rear paddle | momentary |

Types as reported by the user, 2026-09-30. SE was confirmed latching on the R1's *View Channels*
page the same day: pressed and released, CH8 stays until pressed again.

## Switch assignment

| CH | AUX | Function | R1 | V12 MAX |
|---|---|---|---|---|
| CH5 | AUX1 | ARM | **SA** | SA |
| CH6 | AUX2 | ANGLE / acro / TURTLE | **SB** | SB |
| CH7 | AUX3 | PREARM | **SF** (momentary paddle) | SD (momentary) |
| CH8 | AUX4 | BEEPER | **SE** (latching paddle) | front button 3 |
| CH9 | AUX5 | rate profile (+ LEDLOW on the Pavo20) | **SC** | SC |
| CH10 | AUX6 | GPS RESCUE, Pavo20 only | **SD** (toggle) | front button 6 |

ARM, modes and rates are on the same letters as the V12. CH1–CH4 are AETR, the R1 default and what
both aircraft expect.

What each position does is set on the aircraft and is not repeated here:

- **Pavo20 Pro II** — `../../pavo20-pro-ii/BINDING_GUIDE.md`, *Switch layout used by these configs*;
  the CH10 rescue line is in `../../pavo20-pro-ii/FAILSAFE.md`
- **Meteor75 Pro** — `../../meteor75-pro/README.md`, *Switches*

### Why rescue is on SD and not a paddle

Copying the V12 by control type would put GPS Rescue on SE, the only latching button. The paddles
sit under the fingers for the whole flight. An accidental rescue hands the quad to a feature that
on the Pavo20 has never worked in the air — its one field trigger, on 2026-09-03, disarmed and
dropped the quad (`../../HANDOFF.md`, *GPS Rescue*). SD is a top toggle and needs a deliberate
reach, as the V12's front button did. The beeper goes on the paddle instead, where a mis-press
costs nothing. Chosen 2026-09-30.

A forgotten SD fails safe. At Betaflight 2025.12.2 an active rescue switch sets
`ARMING_DISABLED_RESC` (`src/main/fc/core.c:408-409`), so SD left up means the quad will not arm —
not a rescue on takeoff.

### Why PREARM is on SF

PREARM is a hold-while-arming control on the V12 too. SF is the R1's only momentary. On a toggle it
would be left up and the two-step arm would stop being two steps. A mis-press in flight does
nothing: PREARM is only consulted while disarmed (`core.c:391-397`).

The rules behind both choices are requirements, not preferences:
`../../openspec/specs/radio/channel-mapping/spec.md`.

## Settings

One R1 model flies both aircraft, as on the V12. Set these once.

| Setting | Where | Value | Why |
|---|---|---|---|
| Models | Model Selection | **one**, for both aircraft | The mapping is identical on both; the Meteor75 ignores CH10. Split only if a real per-aircraft difference appears. |
| Channel mapping | System Settings → Channel Settings → *Mapped Switch* | table above | |
| Output Range | Channel Settings | default (±100%) | The Meteor75's CH9 bands are 900–1200 / 1375–1675 / 1800–2100. A narrowed range can miss one. |
| Center Point | Channel Settings | default | Same reason: the middle position has to land near 1500. |
| Channel Reverse | Channel Settings | only on a channel that reads backwards | ARM must read above 1700 with SA up. |
| Packet Rate | Quick Settings → ELRS Lua | **250Hz** — a standard rate, not a "Full" one | See below. |
| Telem Ratio | Quick Settings → ELRS Lua | anything but Off | Off loses `RxBt`, `GPS`, `Sats` and *Find Drone*. |
| Model Match | Quick Settings → ELRS Lua | **Off** | Unused in this fleet; turning it on is a new way to fail to connect. |
| Throttle Lock | System Settings → Throttle Lock | **Off** | See below. |
| Power | Quick Settings → Power | 250 mW | The manual shows fixed levels (25/100/250/500 mW) and no Dynamic setting. |

**Packet rate.** The R1's ELRS menu has no *Switch Mode*. On a "Full" rate the switch mode decides
whether CH10 is sent at all, and `8ch` drops it (`../README.md`, *What each Full-Res switch mode
actually transmits*). On the standard rates both available modes carry to CH12, so CH10 arrives
regardless. 250Hz is the rate `../../pavo20-pro-ii/BINDING_GUIDE.md` recommends for these quads;
500Hz is also fine. The receiver follows whatever the radio sends, so the V12 stays on `333Hz Full`
with no conflict.

**Throttle Lock is not a disarm.** It forces CH3 to minimum. An armed quad at minimum throttle keeps
its props turning: at Betaflight 2025.12.2 armed-at-minimum is motor idle
(`src/main/drivers/dshot.c:70`), and only disarm sends motor stop (`dshot.c:63`). SA is the kill
switch. Leave Throttle Lock off so nobody reaches for it expecting it to be one.

## Pairing

By **binding phrase only**. Enter the fleet's phrase on the R1; do not use the R1's *Bind* button or
put a receiver into bind mode. Confirmed working with both aircraft on 2026-09-30, with no change to
either receiver. More in `../README.md`, *Pairing*.

## Bench check

Do this per aircraft before flying it on the R1. **Props off.** Needs USB and Betaflight
Configurator only — no goggles. Both quads have the ELRS receiver on the flight controller, so USB
power should bring the link up; plug a battery in if it does not.

On the R1 first: Quick Settings → Channels → *View Channels*, and check each switch moves only its
own channel.

**Do not stir the sticks, or run the R1's Gimbal Calibration, with a quad powered and disarmed.**
Throttle high + yaw left + pitch down + roll centred, held about 50 ms, is Betaflight's accelerometer
calibration stick command (`src/main/fc/rc_controls.c:290-292` at 4.5.1), and a calibration taken
that way overwrites the saved level reference. It is believed to have happened to the Meteor75 on
2026-09-30 (`../../HANDOFF.md`, *Accelerometer X axis*). On the Pavo20, GPS Rescue depends on it.

Then, with the quad on USB and the **Receiver** tab open:

1. **SA** — AUX1 goes above 1700 when up. Modes tab: ARM range lights.
2. **SB** — AUX2 shows three values: low under 1300 (ANGLE), mid, high above 1700 (TURTLE).
3. **SF** — AUX3 goes above 1700 only while held. PREARM lights.
4. **SC** — AUX5 shows three values. On the Meteor75 they must fall inside 900–1200, 1375–1675 and
   1800–2100.
5. **SE** — AUX4 goes above 1700 and **stays there after release**. The quad beeps.
6. **SD, Pavo20 only** — AUX6 goes above 1700 and GPS RESCUE lights. **If AUX6 sits at exactly
   1500 while SD moves, CH10 is not being sent** — Betaflight presets every channel to 1500 and only
   overwrites the ones that arrive (`src/main/rx/rx.c:308`). Check the packet rate before the
   mapping.
7. **Grip test** — hold the radio as you fly and squeeze and brush both paddles. AUX6 must not
   move.

**Arming.**

- **Meteor75, on the bench:** throttle at minimum, hold SF, flip SA. It should arm. Flip SA down and
  the motors stop. If it will not arm, run `status` in the CLI and read *Arming disable flags*.
- **Pavo20, indoors: it will not arm, and that is correct.** It has
  `gps_rescue_allow_arming_without_fix = OFF` and `gps_rescue_min_sats = 8`, which block arming
  without a GPS fix (`core.c:400-406`). Instead: SD down, hold SF, flip SA, run `status`. `GPS`
  should be the **only** flag. Then put SD up and check `RESC` appears too. Arm it for real outdoors
  with a fix, props still off.

## What is not verified

As of 2026-10-01.

**Verified:**

- **Bench check, both aircraft, 2026-09-30.** Every AUX value as described, AUX6 on SD included;
  grip test clean; the Meteor75 armed on the bench.
- **Arming blocks.** The Pavo20 refused to arm indoors without a fix and armed outdoors on
  2026-10-01 once it had one (up to 32 satellites, reached quickly). SD up refusing to arm was
  confirmed by the pilot the same day. `status` was never read, so which flags were set is inferred
  from behaviour, not observed.
- **Flight, both aircraft, 2026-10-01** — the Meteor75 also on 2026-09-30. Pilot's report: everything
  worked as expected, no problems noticed, motors not hot.
- **GPS Rescue switch.** SD triggered a rescue in flight on 2026-10-01, and flipping it off handed
  control back at once. The R1 side works; the rescue itself is not yet trustworthy
  (`../../HANDOFF.md`, *GPS Rescue*), and `../../pavo20-pro-ii/FAILSAFE.md` governs.
- **Find Drone with a fix.** Used on 2026-10-01 and preferred by the pilot to the GPSQR widget.
- **Alarms.** The R1 has them — confirmed by the pilot 2026-10-01. Which sensors and thresholds are
  set is not recorded. The thresholds in `../README.md`, *Battery voltage warning*, apply; on the
  Pavo20 `RxBt` is pack voltage unless `report_cell_voltage` is ON.

**Not verified:**

- **Find Drone with no fix — not tested, by the pilot's choice** (2026-10-01): it will only be used
  while the GPS is working. Worth knowing why that is not quite the same thing: the Pavo20 sends
  coordinates to the radio whether or not it has a fix (`../../HANDOFF.md`, *GPSQR widget*, the Mali
  position of 2026-09-03), and after a crash the GPS may be the thing that has just restarted. The
  manual says Find Drone needs at least 6 satellites. **Check `Sats` before trusting a pin.**
- **The R1's ELRS version.** Known to link to the 3.5.6 receivers. Only matters for the Full-Res
  channel tables, which the 250Hz choice avoids. Read it off the radio for the record.
