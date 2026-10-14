# Meteor75 Pro II setup — Oxbot R1 and O4 Wide

This procedure applies to [M75_PRO_II_ELRS_V1.txt](M75_PRO_II_ELRS_V1.txt) on the firmware recorded in [README.md](README.md).
The pilot reported that the binding phrase is already configured on 2026-10-12.
Start with the existing phrase configuration.
The pilot reported O4 activation complete on 2026-10-12.
Section 2 remains the reference procedure; continue with the goggles check for this aircraft.

## 1. Prepare the aircraft

**Remove the propellers before you connect a battery for a bench procedure.** The motors can start without a command.
**Supply airflow across the powered air unit.** The air unit can overheat on the bench.

1. Put SA in the disarmed position.
2. Put SB in its middle position.
3. Put SC in its low position.
4. Release SF.
5. Put SE in its inactive position.
6. Connect a fan for the air unit.
7. Prepare USB data cables for the flight controller and the air unit.

Use the flight-controller USB connection for Betaflight.
Use the O4 Air Unit's own USB-C port for DJI Assistant 2.
These connections have different functions.

## 2. Activate the O4 Air Unit

The pilot performs activation with their own DJI account.
The repository does not store DJI credentials.
Use the [DJI O4 downloads](https://www.dji.com/o4-air-unit/downloads) and [activation manual, section 3.1](https://dl.djicdn.com/downloads/DJI_O4_Air_Unit_Series/UM/DJI_O4_Air_Unit_Series_User_Manual_v1.0_en.pdf).

1. Install **DJI Assistant 2 (Consumer Drones Series)** on the computer.
2. Connect the aircraft battery to power the installed air unit.
3. Connect the air unit's USB-C port to the computer with a data cable.
4. Open DJI Assistant 2.
5. Sign in with your DJI account.
6. Select the connected O4 Air Unit.
7. Complete the activation prompts.
8. Record the successful activation confirmation or the confirmed already-activated state.
9. Record the air unit firmware version.
10. Disconnect the battery after the session.

If the device is absent, examine aircraft power and the air unit USB connection.
If activation fails, record the exact error.
Do not mark activation complete from a live image alone.
Activation and firmware updates are separate operations.

## 3. Link the goggles

Use [DJI's O4 linking guide](https://repair.dji.com/help/content?customId=01700011934&lang=en&paperDocType=ARTICLE&re=DK&spaceId=17).
Use the DJI Goggles 3 procedure.
The pilot confirmed that model and reported the goggles link complete on 2026-10-12.
DJI firmware versions are not recorded. Confirm the live image during the OSD bench check.

1. Record the goggles model and firmware version.
2. Make sure the goggles are activated.
3. Power the aircraft with the fan on.
4. Select the appropriate O4 product in the goggles.
5. Start the air unit's link mode with its link button.
6. Start the goggles' link mode through the applicable procedure.
7. Confirm a stable live camera image.
8. Disconnect the battery after the check.

The aircraft uses the Oxbot R1 over ELRS.
A DJI remote controller link is not part of this setup.
If DJI reports incompatible firmware, record the message before any update.

## 4. Confirm the existing R1 connection

Use [radio/oxbot-r1/README.md](../radio/oxbot-r1/README.md) for the radio settings and physical controls.
The agreed aircraft functions and SC order are in [README.md](README.md#switches).
The R1 uses OXBOT OS; the EdgeTX Lua procedures do not apply.

1. Leave the configured binding phrase unchanged.
2. Turn on the R1.
3. Connect the flight controller to Betaflight Configurator.
4. Open the Receiver tab.
5. Confirm separate roll, pitch, throttle, and yaw responses on CH1–CH4.
6. Confirm that SA, SB, SF, SE, and SC move CH5, CH6, CH7, CH8, and CH9, respectively.
7. Confirm the channel values against the aircraft table.

Keep the sticks away from calibration-command combinations.
Do not calibrate the R1 gimbals with the aircraft powered.
The [firmware's stick commands](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/rc_controls.c#L304) include accelerometer calibration and PID-profile changes.

If the channels do not respond, first examine the link and settings below.
Do not assume a configured phrase proves a receiver link.

```text
serial
get serialrx_provider
status
```

The expected receiver settings are UART3 with SERIAL_RX and `serialrx_provider = CRSF`.
The O4 video assignment remains UART4 with MSP + VTX_MSP.
Do not move the receiver or video serial assignment to resolve an unmeasured fault.

Only if a later examination finds a phrase mismatch, use the existing fleet phrase through the receiver Web UI.
ExpressLRS 3.x supports a phrase change through that UI without a firmware flash.
The TX and RX must use compatible major versions.
Use the [official phrase instructions](https://www.expresslrs.org/quick-start/binding/) and [Web UI guide](https://www.expresslrs.org/quick-start/webui/).
Do not use traditional bind mode for this fleet.

## 5. Examine build-specific CLI settings

The pilot supplied the required readbacks on 2026-10-12; all requested settings exist.
The [capture](<dumps/BTFL_cli_METEOR75_PRO_20261012_193623_BETAFPVG473 - settings check.txt>) records this completed check.

The source and build features support the requested layout.
The actual CLI must still accept each setting before the configuration is applied.

1. Open the CLI.
2. Run the following read-only commands in small groups.
3. Confirm that each setting exists.

```text
get thr_hover
get rateprofile_name
get osd_ah
get osd_stick_overlay
get osd_rate_profile_name
get osd_sys_vtx_temp
```

If a command reports an unknown setting, stop before application.
Send the response for examination.
Do not paste an unsupported command inside the batch.

## 6. Apply the aircraft configuration

1. Confirm the target and firmware against the [aircraft baseline](README.md#aircraft-baseline).
2. Save a fresh `diff all` backup before any configuration write.
3. Keep the propellers removed.
4. Open [M75_PRO_II_ELRS_V1.txt](M75_PRO_II_ELRS_V1.txt).
5. Paste the file in order, in small chunks.
6. Examine the CLI response after each chunk.
7. Let the final `save` command reboot the board.
8. Put the aircraft on a level surface.
9. Run **Sensors → Calibrate Accelerometer**, as this Configurator's warning directs.
10. Confirm that the Setup model follows roll and pitch tilts correctly.
11. Confirm that the model returns to level on the level surface.

If any CLI line fails, stop the procedure.
Resolve the error before another application attempt.
A batch error can prevent `save`; an error-free paste does not prove the aircraft flies correctly.
See the [shared CLI reference](../docs/betaflight-reference.md).

## 7. Capture and compare the result

1. Reconnect after the reboot and calibration.
2. Run `diff all`.
3. Run `status`.
4. Save both outputs in a dated capture under `dumps/`.
5. Redact the `mcu_id` and signature values before you share the file.
6. Send the capture for comparison with the committed configuration.

Expected differences include the new calibration, comments, and pinned settings that equal defaults.
They do not include changed PID values, filters, motor settings, or battery thresholds.
See [source review](SOURCE_REVIEW.md#expected-round-trip-differences) for the pinned defaults.

Use the following targeted readbacks if a default is absent from the diff.
Repeat the rate readbacks for profiles 1 and 2 through the Configurator's profile selector.
Restore rate profile 0 before the final capture.

```text
profile 0
get profile_name
get p_roll
get p_pitch
get auto_profile_cell_count
rateprofile 0
get rates_type
get rateprofile_name
get rc_rate
get srate
get expo
get thr_
get throttle_limit
```

## 8. Complete the bench checks

Keep the propellers removed for these checks.
Keep the fan on during battery-powered video checks.
Exit the CLI before actual arming or telemetry checks.

| Check | Required observation |
|---|---|
| Controls | Receiver/Modes tabs agree with the aircraft table; SB middle does not select HORIZON |
| PREARM | After reboot, SA alone refuses ARM; SF followed by SA permits ARM when other conditions permit it |
| Disarm | SA low stops every motor |
| Beeper | SE selects BEEPER and stays latched after release |
| SC | Low/middle/high selects Stock/Cine/Park with the specified rate values |
| Throttle | All three selected profiles have the same stock throttle settings |
| Battery | A freshly charged intended 1S pack registers as 1S; voltage is plausible |
| PID profile | Profile 0 remains `GF 1811`; `p_roll = 40`, `p_pitch = 52` |
| Telemetry | R1 `RxBt` follows the pack voltage after the CLI is closed |
| Motors | Correct motor order/direction; valid telemetry for every motor with battery power |
| OSD | Supported v1 positions/visibility; readable warnings and selected rate name |

If `DSHOT_TELEM` persists with battery power, record `status` and the motor telemetry results.
Do not disable bidirectional DShot to hide the flag.
If the battery registers as 0S or 2S, stop before flight.
Keep the captured battery settings until the measurement identifies a necessary correction.

### Failsafe check

1. Run `get failsafe` before the test.
2. Record the configured procedure and delays.
3. Confirm the expected default procedure is `DROP`.
4. Exit the CLI and disconnect the Configurator.
5. Arm with the propellers removed and the throttle at minimum.
6. Turn off the R1 to create a link loss.
7. Confirm that the aircraft disarms and stops the motors after the configured failsafe response.
8. Put SA low before the R1 is turned on again.
9. Record the observed response and delay.

The [recorded firmware source](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/flight/failsafe.c#L71) sets `DROP` as the default.
The supplied diff contains no failsafe override.
If the actual saved procedure differs, stop and examine the capture before the test.
Do not perform a radio-off failsafe test in flight.

## 9. Complete the flight checks

1. Complete the required bench checks first.
2. Install the propellers in the confirmed motor directions.
3. Select SC low for Pro II Stock.
4. Perform a short first flight in a clear area.
5. Examine Angle behaviour and Acro control.
6. Land if the aircraft oscillates, loses video, or responds incorrectly.
7. Examine motor temperatures after the flight.
8. Compare Cine and Park on later short flights.
9. Report the selected profiles, throttle response, video stability, and any abnormal behaviour.

The tune is preserved, but this aircraft's flight behaviour remains unverified until the pilot reports it.

## Rollback

Use the [baseline capture](<dumps/BTFL_cli_METEOR75_PRO_20261012_184633_BETAFPVG473 - baseline.txt>) only on this aircraft and the recorded firmware.

1. Remove the propellers.
2. Paste only the configuration section, through its `save` line, in chunks.
3. Exclude the `status` output after that section.
4. Calibrate the actual, level aircraft after the reboot.
5. Take a fresh capture for comparison.

Rollback restores the factory HORIZON and CH7 TURTLE assignments.
It removes the new PREARM assignment and SC profile selection.
The reusable configuration deliberately contains no saved accelerometer calibration.
