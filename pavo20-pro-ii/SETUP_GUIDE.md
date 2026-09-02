# Pavo20 Pro II — Setup Guide

Work through this in order. **Props off until step 9.**

---

## 1. Back up the factory config first

Before changing anything, capture the stock config. If a later step goes wrong this is your
way back, and it is the baseline every tuned variant in this repo is built from.

1. Connect the quad to Betaflight Configurator over USB (no battery needed).
2. Go to the **CLI** tab.
3. Type `diff all` and press Enter.
4. Copy the **entire** output.
5. Save it to `dumps/` as:
   `BTFL_cli_backup_PAVO20PRO2_<YYYYMMDD>_<BOARDNAME> - original.txt`

Also click **Save backup** on the Configurator's landing page for a binary backup.

> The `board_name` line in that output tells you which variant you have — `BETAFPVF405` (3S)
> or `BETAFPVG473_V3` (4S). Everything downstream depends on it. See `HARDWARE.md`.

## 2. Check firmware version

Read the `# version` line at the top of your `diff all`.

- **2025.12.2** — good, this is what BetaFPV ships. Leave it.
- **2025.12.1** — known no-boot bug on the F405 board. Flash 2025.12.2. See `HARDWARE.md`.
- Anything older — it works, but 2025.12.2 is the tested baseline for this airframe.

If you do flash, use **Full chip erase** and then re-apply your config from the CLI dump.
Do not restore a binary backup across firmware versions.

## 3. Bind the radio

Follow `BINDING_GUIDE.md`. Get a solid link and confirm stick movement in the **Receiver** tab
before continuing. Nothing below is worth doing until the radio works.

## 4. Verify the O4 air unit

Follow `DJI_O4_SETUP.md`. Confirm:

- UART4 has **MSP** + **VTX (MSP)** enabled
- `osd_displayport_device = MSP`
- Canvas Mode is on in the goggles
- You can see the Betaflight OSD in the goggles on battery power

## 5. Set up modes

In the **Modes** tab, or via the aux lines in the CLI config. Layout (matches your Meteor75):

| Switch | Position | Mode |
|---|---|---|
| AUX1 / CH5 | high | ARM |
| AUX2 / CH6 | low | ANGLE |
| AUX2 / CH6 | mid | ACRO |
| AUX2 / CH6 | high | TURTLE |
| AUX3 / CH7 | high | PREARM |
| AUX4 / CH8 | high | BEEPER |

CLI form:

```
aux 0 0 0 1700 2100 0 0
aux 1 1 1 900 1300 0 0
aux 2 13 3 1700 2100 0 0
aux 3 35 1 1700 2100 0 0
aux 4 36 2 1700 2100 0 0
```

## 6. Set up rates

Two rate profiles, same pattern as your Meteor75:

- **rateprofile 0 — "Cine"**: low rates, high expo. Smooth, deliberate stick inputs, good footage.
- **rateprofile 1 — "Stock"**: BetaFPV's factory rates, for when you want more authority.

Bind a switch or the ELRS Lua rate-profile selector if you want to swap in the air.

## 7. Battery and voltage settings

Set these to match your actual packs:

```
set vbat_max_cell_voltage = 435     # 4.35V, LiHV-safe headroom on the OSD scale
set vbat_warning_cell_voltage = 350
set vbat_min_cell_voltage = 330
```

For the **4S variant** the stock current sensor scale is `265`:

```
set ibata_scale = 265
```

Confirm `auto_profile_cell_count` is set correctly, or leave it at `0` to auto-detect.

**Calibrate the current sensor properly** rather than trusting the default — fly a pack, compare
`mah_drawn` in the OSD against what your charger puts back in, and scale `ibata_scale` by the ratio.
On a cinewhoop where you are watching remaining capacity closely, this is worth the 10 minutes.

## 8. Accelerometer calibration

Put the quad on a genuinely level surface — a table edge is not level, use a spirit level or a
phone app. Then **Setup** tab → **Calibrate Accelerometer**.

This writes `acc_calibration`, which is unique to your board and airframe. **Never copy this value
from another quad's config**, including from the Meteor75 dumps in the neighbouring folder.
ANGLE mode drifting is almost always a bad accelerometer calibration.

## 9. Bench checks — still no props

1. **Motor direction:** Motors tab, spin each motor, confirm the direction matches the diagram.
   Fix in the ESC Configurator (Bluejay) or by reversing in the Motors tab, not by swapping wires.
2. **Motor order:** motor 1 = rear right, 2 = front right, 3 = rear left, 4 = front left.
3. **Bidirectional DShot:** confirm RPM telemetry shows in the Motors tab. This build relies on it
   for RPM filtering — if it does not work, the filtering config is wrong for the hardware.
4. **`status` in CLI:** check `Arming disable flags` is empty when you flip PREARM and ARM.

## 10. Props on, first hover

- Fit the Gemfan D2.2 3-blade props. They are **screw-mount** on this model — actually tighten them,
  and check them before every flight.
- **Check every prop is the right way up.** An inverted prop still produces some thrust, so the
  quad flies — badly, and with a loud scream from about 35-40% throttle upward. It reads exactly
  like a PID oscillation. Happened on this quad 2026-09-02; the fix was flipping one prop.
  Check orientation before suspecting the tune. This is an upgrade over the friction-fit props on the older
  Pavo20 Pro, but it means a loose screw is now a thing that can happen.
- First flight in **ANGLE** mode, low to the ground, over grass.
- Hover 30 seconds. Land. **Feel the motors.** Warm is fine, too hot to hold is not — that means
  the tune is oscillating and you should stop and look at the filtering.
- Check the O4 temperature in the OSD after a hover. A ducted frame has poor airflow.

## 11. Then tune

The stock BetaFPV tune on this airframe is genuinely good — reviewers rate it as needing minimal
adjustment. Fly it stock for a few packs before changing PIDs.

If you do tune, change one thing at a time and log it in a new `PAVO20PRO2_*_V<n>.txt` variant in
this repo so you can always go back.

---

## Cinewhoop-specific notes

A ducted 2.2" behaves differently from your Meteor75 whoop, and differently from an open freestyle quad:

- **Prop wash is the enemy, not the target.** Ducts recirculate air. Expect more low-frequency
  noise and more prop wash oscillation in descents than on an open frame. Descend slowly and on an
  angle rather than straight down.
- **Ducts add resonance.** The frame + duct assembly has its own resonant frequency that a bare
  frame does not. If you get a persistent oscillation the dynamic notch cannot catch, check for a
  cracked duct or a loose canopy screw before touching PIDs.
- **Smooth footage comes from rates and expo, not from PIDs.** Get the rates right first.
- **Weight matters more here.** The O4 Pro plus a 4S pack is a lot of mass on a 2.2" frame. Do not
  expect freestyle authority, and do not tune toward it.

---

# Applying a config, and flashing firmware

## Option A — apply the config without flashing (do this first)

`PAVO20PRO2_ELRS_V1.txt` sets its own `resource`, `timer` and `dma` lines, so it applies correctly
on the firmware already on the quad. Nothing about the GPS fix requires new firmware.

1. **Props off. Battery disconnected. USB only.**
2. Connect the quad, open Betaflight Configurator, click **Connect**.
3. Go to the **CLI** tab.
4. Paste the contents of `PAVO20PRO2_ELRS_V1.txt` — **a few lines at a time**, not all at once.
   The Configurator CLI has dropped pasted lines on this quad before, which produced a very
   confusing GPS fault. Watch for any red error text as you go.
5. The file ends with `save`, which reboots the board.
6. Reconnect, **Setup** tab, **Calibrate Accelerometer** with the quad level.
7. Connect the O4 and a battery, open the **GPS** tab, look for a satellite count.

If GPS works, the job is done. Flashing is then optional and can wait.

## Option B — flashing BF2025.12.5

Worth doing for BetaFPV's newer O4 PID profiles and gyro calibration fix, but it is not needed to
fix GPS. Do it when you have time, not in a hurry before a flight.

### Before you start

- **Props off. Battery disconnected. USB only, the whole time.**
- Your existing config is already saved in `dumps/`. A full chip erase wipes the board completely,
  so that backup is what you fall back on.
- Use a **data** USB cable. Charge-only cables are a classic first-flash time sink — if the board
  does not appear at all, suspect the cable before anything else.
- Do not unplug or close the Configurator while the progress bar is moving.

### Steps

1. Open Betaflight Configurator and go to the **Firmware Flasher** tab. Do **not** click Connect
   first — the flasher works from the disconnected state.
2. Enable **Full chip erase**.
3. Click **Load Firmware [Local]** and select
   `BF2025.12.5 Cube G473_30A_Pavo20 Pro II_ELRS 20260812.hex`.
4. Click **Flash Firmware**.
5. Wait for **Programming: SUCCESSFUL**. The board reboots on its own.
6. Click **Connect**, go to the **CLI** tab, and paste `PAVO20PRO2_ELRS_V1.txt` in small chunks.
7. **Calibrate Accelerometer.**

### If the board is not detected for flashing

The flasher needs the board in **DFU** (bootloader) mode. Betaflight normally puts it there
automatically. If it does not:

- **Manual entry:** unplug USB, hold the **BOOT** button on the flight controller, plug USB back in
  while still holding, then release. The board enumerates as `DFU` in the Configurator's port list.
- **Windows driver problem:** if Windows shows an unrecognised `STM32 BOOTLOADER` device and the
  Configurator cannot see it, the driver needs replacing with WinUSB. **ImpulseRC Driver Fixer** is
  the one-click tool for this; **Zadig** does the same job manually. This is the single most common
  obstacle on a first flash on Windows, and it is a driver issue, not a broken board.

### After any full chip erase

These are wiped and must be restored — they are in the config file, but the accelerometer is not:

- `resource` / `timer` / `dma` remaps for the LED strip (in the config file)
- `acc_calibration` — **re-run Calibrate Accelerometer on the actual airframe**

`mcu_id` and `signature` are read-only board properties. They are not restored by pasting a config
and do not need to be.

---

# Troubleshooting notes

## The buzzer is silent on USB — this is normal

With USB connected and **no battery**, Betaflight deliberately silences the beeper. From `beeper.c`:

```c
static bool beeperUsbSuppressed(void)
{
    return (beeperConfig()->beeper_off_flags & BEEPER_GET_FLAG(BEEPER_USB))
        && getBatteryState() == BATTERY_NOT_PRESENT
        && (usbCableIsActive() || mspSerialIsConfiguratorActive());
}
```

All three must be true: the `ON_USB` beeper is disabled (the default), no battery is detected, and
USB or the Configurator is active. It keeps the bench quiet while configuring.

**Plug a battery in and the beeper works normally**, even with USB still connected — the battery
check is there so in-flight beeping is never suppressed.

To test the buzzer directly at any time:

```
play_sound
```

`beeper` lists which conditions are enabled; `resource show` should report `A08: BEEPER`.

## Power-cycle on battery after applying a config, before judging the RX link

`save` reboots the flight controller, but the onboard ELRS module does not necessarily get a clean
power cycle with it, and can come back not linked. Observed 2026-09-01: no link after pasting a
config; unplugging and reconnecting the battery restored it immediately.

Do a full battery power cycle before troubleshooting a receiver that stops connecting right after
a config change.

## OSD altitude reads your ground elevation while disarmed

Once GPS is working the OSD altitude shows a large number on the ground (~124 m at this quad's
home field) rather than 0. Two reasons, both normal:

1. **The altitude zero point is set at arming, not at boot.** From `position.c`:

   ```c
   if (isArmed != wasArmed) {
       positionEstimatorResetZ();
       positionResetAltitudeState();
       wasArmed = isArmed;
   }
   ```

   The estimate deliberately keeps running while disarmed so sensor views show live data.

2. **GPS reports altitude above mean sea level.** Before GPS worked, the reading was baro-only and
   the baro zeroes at power-up calibration, so it showed 0.

In flight the number is height above your takeoff point, which is what matters. To make it
ground-relative while disarmed as well, `get altitude_source` lists the options for selecting
baro-only, and `altitude_prefer_baro` (0-100) weights the fusion instead. Leaving it on the default
gives the better in-flight estimate.

## `profile_name` and `rateprofile_name` are limited to 8 characters

A longer name fails with `STRING MUST BE 1-8 CHARACTERS` and **aborts the entire batch at `save`**,
so nothing is written. `craft_name` allows 16. Watch for this when editing the config files by hand.

## Two symptoms that are not faults

- **"Sensor lost" on the radio after a CLI command.** Betaflight skips the telemetry task whenever
  the CLI is open (`if (!cliMode && featureIsEnabled(FEATURE_TELEMETRY))` in `fc/tasks.c`).
  Expected, every time.
- **`GPS: connected` in `status`.** Proven meaningless on the NMEA provider — it reads true with
  the GPS module physically unplugged. See `GPS_SETUP.md`.
