# Design

## Context

See `proposal.md` for the reason and `specs/meteor75-pro-ii/flight-config/spec.md` for the requirements.
This design applies because the change adds an aircraft, shared radio references, and hardware verification procedures.

The pilot supplied `C:/Users/ezagv/Downloads/BTFL_cli_METEOR75_PRO_20261012_184633_BETAFPVG473.txt` on 2026-10-12.
It contains both `diff all` and `status`.
The version header reports `2025.12.5-alpha`, commit `eb2bb5a33`, and config revision `1359bbe`.
The build key is `0fc940a951a76ec788851f939db8ed94`; its status label says `2025.12.4`.
Use the firmware commit for source references; do not substitute the build label for the reported firmware version.

| Observed baseline | Value |
|---|---|
| Target / gyro | BETAFPVG473 / BMI270 |
| Active PID profile | 0, GF 1811 |
| Active rate profile | 0; all rate blocks contain no overrides |
| Video serial assignment | UART4, MSP + VTX_MSP |
| OSD canvas | MSP, 53 x 20 |
| Board yaw | -90 degrees |
| Battery ceiling / warning | 440 / 345 |
| Telemetry | Enabled |
| Battery during capture | Not present, 0S |
| Receiver during capture | RX rate 0, RXLOSS flag |
| Other arming flags | CLI, MSP, DSHOT_TELEM |

The capture does not prove binding, motor operation, battery detection, activation, video output, or flight performance.
The older Meteor's verified R1 flights do not prove this new aircraft works on that radio.

## Goals / Non-Goals

**Goals:**

- Keep the Pro II baseline as the source for all hardware and tune settings.
- Limit flight behaviour changes to the agreed controls and rate choices.
- Keep each verification claim tied to a dated observation.

**Non-Goals:**

- Change flight-controller firmware, PID values, filters, battery thresholds, or failsafe settings.
- Add an SBUS variant, GPS, or a new transmitter model.
- Activate a DJI account or hardware from the repository tools.
- Update DJI firmware automatically as part of activation.

## Decisions

### 1. Create a separate aircraft configuration from the new capture

Add `meteor75-pro-ii/M75_PRO_II_ELRS_V1.txt`, `README.md`, `SETUP.md`, and `dumps/`.
Archive a redacted copy of the supplied capture with its date and an explicit `baseline` suffix.
Call it a supplied baseline, not proof of factory provenance or successful configuration application.

The reusable file will retain `batch start`, `defaults nosave`, and `save`.
Remove board identifiers and calibration from that file.
Keep the raw calibration in the baseline as an observation of this aircraft.
Require fresh calibration after application; absence from a file does not prove a reset preserves the previous calibration.
Use the display name `Meteor75 Pro II`, within the craft-name limit.

The alternative was to copy the older Meteor file and change its rates.
That would also transfer the wrong tune, filters, battery thresholds, and board orientation.

Preserve the current serial configuration.
The [board config at revision 1359bbe, lines 91-103](https://github.com/betaflight/config/blob/1359bbe/configs/BETAFPVG473/config.h#L91) supplies UART3/CRSF receiver defaults.
Read back receiver settings when the aircraft is available; its supplied capture shows no live link.
This change does not alter wiring or prescribe physical pads.

### 2. Retain the R1 channel assignments and replace the aircraft mode ranges

Use the R1's existing SA, SB, SF, SE, and SC channel assignments.
Replace the factory HORIZON assignment and CH7 TURTLE assignment with the specified v1 mode layout.
Set PREARM on CH7 and TURTLE on CH6 high.
Document that SF currently requests TURTLE until the aircraft configuration is applied.

Keep the existing fleet phrase procedure and shared R1 link settings.
Link to `radio/oxbot-r1/README.md`; do not copy EdgeTX/Lua procedures into the R1 setup.
Keep Throttle Lock disabled as the shared radio instructions require.
No GPS Rescue assignment belongs to this aircraft.

### 3. Make rate profile 0 Stock and preserve the stock throttle settings everywhere

Use `Stock`, `Cine`, and `Park` as the profile names.
Each name fits the eight-character limit.
End the configuration on rate profile 0 so the initial saved selection is Stock.
CH9 then selects the active profile from the physical SC position.

| SC | Profile | Rotation curve source | Throttle source |
|---|---|---|---|
| Low | 0, Stock | Defaults at firmware commit eb2bb5a33 | Pro II stock |
| Middle | 1, Cine | V1 Cine rotation values | Pro II stock |
| High | 2, Park | V1 Park rotation values | Pro II stock |

Use the numeric values in the spec, with `rates_type = ACTUAL` explicit in each profile.
Pin the stock settings where the firmware exposes them, even when `diff all` omits those defaults.
Verify each CLI name against the recorded source or the aircraft's `get` output before it enters the reusable file.
Source review on 2026-10-12 confirmed `thr_hover` in `src/main/fc/parameter_names.h:53` and its registry entry in `src/main/cli/settings.c:1097`.
Leave unused rate profile 3 at its baseline state.

Three identical stock profiles would preserve SC mechanically but remove the agreed comparison choices.
The older Cine/Park throttle curve would introduce a throttle change whenever SC moved.

### 4. Transfer OSD positions and visibility without copying unrelated v1 settings

Use the OSD position lines in `meteor75-pro/M75_PRO_ELRS_V1.txt` as the layout reference.
Retain the Pro II's alarm thresholds and MSP video settings.
Check the conditional elements against the installed build before application.
Pay particular attention to stick overlays, artificial horizon, profile name, and system VTX temperature.
If the build omits an optional element, record the limitation and omit its unsupported command.
Do not flash firmware to obtain an optional layout element.

Source review on 2026-10-12 found the build metadata and feature definitions support all requested v1 layout elements.
No element was omitted. Actual CLI and goggles checks remain pending.

The alternative was to copy the whole v1 master block.
That would transfer settings outside the agreed layout scope.

### 5. Put O4 activation before the goggles and OSD checks

Add the activation procedure to `meteor75-pro-ii/SETUP.md`.
Use DJI Assistant 2 (Consumer Drones Series) from the [official O4 downloads](https://www.dji.com/o4-air-unit/downloads).
The pilot will power the installed air unit through the aircraft and connect its own USB-C port to the computer.
The flight-controller USB connector serves Betaflight; it is not the O4 activation connection.
The pilot will use their own DJI account and complete the displayed activation prompts.

Require propeller removal and external airflow for the powered bench session.
Record successful activation, an already-activated state, or the exact activation failure.
DJI's [manual, sections 3.1 and 4.1](https://dl.djicdn.com/downloads/DJI_O4_Air_Unit_Series/UM/DJI_O4_Air_Unit_Series_User_Manual_v1.0_en.pdf) supplies the activation and ventilation requirements.
Keep DJI activation, goggles linking, and ELRS binding as separate procedure steps.
The pilot reported the binding phrase already configured on 2026-10-12; the setup procedure starts with a link check.
Use the actual goggles model's official link procedure when the pilot performs that step.
Record DJI firmware versions; resolve a compatibility failure as a specific follow-up rather than an automatic update.

### 6. Keep aircraft values in the aircraft folder

Update fleet links in `README.md`, `radio/README.md`, and `radio/oxbot-r1/README.md` where applicable.
Add a link in `radio/v12-max/README.md` only if its aircraft coverage needs the new aircraft.
Do not claim V12 bench or flight verification for the Pro II.
Document the different SC profile order through aircraft links rather than a shared rate-value table.
Update the aircraft inventory in `openspec/config.yaml` and add the new state in `HANDOFF.md`.
No existing radio requirement needs a delta; its current requirements already apply.

## Risks / Trade-offs

- More rotation at partial stick on Stock -> Display the selected name and explain the comparison with v1 Cine and Base.
- Wrong SF assignment before configuration application -> Identify the factory behaviour and verify PREARM with the propellers removed.
- Alpha firmware or unsupported commands -> Pin source references to the captured commit and require error-free CLI application.
- Dropped paste lines -> Paste in chunks and compare a fresh capture after reboot and calibration.
- Missing optional OSD elements -> Record build limitations and verify the remaining layout in the goggles.
- O4 overheating during activation -> Supply external airflow and disconnect aircraft power after the procedure.
- A default omitted from `diff all` -> Use targeted readback and list expected default omissions in the comparison record.

## Migration Plan

1. Implement the aircraft files and shared documentation updates from the supplied baseline.
2. Complete source review against the baseline, spec, and recorded firmware source.
3. Give the pilot the configuration and setup procedure for review.
4. The pilot removes the propellers before any powered bench verification.
5. The pilot completes O4 activation and the goggles link with airflow across the air unit.
6. The pilot applies the configuration in chunks and examines every CLI response.
7. The pilot calibrates the accelerometer and supplies a fresh capture after reboot.
8. Compare the capture and complete the R1, battery, motor, and OSD bench checks.
9. The pilot completes short flight checks for each rate profile and reports the result.
10. Record only completed observations and keep pending hardware tasks unchecked.

Rollback uses this aircraft's redacted baseline on the same target and firmware.
Require calibration and a fresh comparison after rollback.
The baseline restores factory mode assignments; it does not retain the new PREARM layout.
Disconnect power or disarm if the setup fails a bench check.

## Open Questions

All checks below remain unverified on the new aircraft. The pilot performs the hardware checks; Codex reviews the supplied evidence.

- **Activation and goggles:** Does DJI Assistant 2 confirm activation, and do the actual goggles show a stable live image?
  Activation confirmation, the goggles model, and a completed video/OSD check will settle this.
- **Receiver and controls:** Do CH1-CH9 respond correctly on the R1, and does SF permit ARM only as specified?
  Receiver/Modes-tab observations and a props-off arming/disarming check will settle this.
- **Motor telemetry:** Does DSHOT_TELEM clear with the battery connected, and do all motors report valid telemetry?
  A battery-powered status capture and props-off motor check will settle this. Do not disable bidirectional DShot to hide a failure.
- **Battery and profile:** Does a freshly charged intended 1S pack register as 1S with PID profile 0 active?
  The battery-powered status capture and PID readback will settle this. A failure requires diagnosis before flight.
- **Failsafe:** What saved failsafe procedure applies, and does link loss produce its expected response?
  Read back the saved settings and perform a props-off link-loss check before flight. Keep the baseline settings unchanged.
- **Calibration and orientation:** Does the calibrated Setup model follow each physical tilt correctly?
  The pilot's calibration and attitude-response check will settle this.
- **Rates, throttle, and tune:** Are the values saved correctly, and does the aircraft behave acceptably on each SC position?
  Readback settles the saved values. Short flights, motor temperature observations, and pilot feedback settle flight behaviour.

CLI acceptance proves syntax and persistence only. It does not prove receiver operation, safe motor behaviour, or flight performance.
