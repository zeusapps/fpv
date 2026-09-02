# Handoff — state of the repo as of 2026-09-02

Written so a session with no prior context can pick this up. Read this, then
`docs/betaflight-reference.md`, then the folder for whichever aircraft you are working on.

## Where things stand

| Aircraft | Status |
|---|---|
| **Pavo20 Pro II** | Flying. Rewired and reconfigured 2026-09-01. Active work is here. |
| **Meteor75 Pro** | Stable, documented, no outstanding work. |
| **FireFly25** | Bare defaults capture only. Not actively worked on. |

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

## Outstanding work

### 1. Fresh `diff all` baseline

The dump in `pavo20-pro-ii/dumps/` is the **pre-rewire** state. Capture a new one from the flying
aircraft and save it alongside, named with the date. Redact `mcu_id` before committing — this repo
is public.

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

`openspec/` is initialised with `config.yaml` but has no specs or changes yet. The GPS/SBUS pin
constraint is the natural first spec — it is a rule that outlived the change that discovered it and
would bite again on any rebuild.

### 4. Optional: retest the UBLOX provider

The FC→module TX path now runs through a new solder joint on T2. UBLOX failed before the rewire,
but that was never cleanly isolated from the pin contention. Worth one bench retest — a real
version string in `status` instead of `version = unknown` means it worked. NMEA is entirely
sufficient if it does not.

### 5. Delete the superseded folders

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
