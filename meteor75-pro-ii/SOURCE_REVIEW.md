# Meteor75 Pro II source review

## Result — 2026-10-12

Source review is complete for [M75_PRO_II_ELRS_V1.txt](M75_PRO_II_ELRS_V1.txt).
All configuration setting names exist in the source registry at firmware commit `eb2bb5a33`.
The review compared the new configuration with the supplied baseline and the older Meteor layout.
The review also examined the recorded cloud build features.

| Verification stage | Evidence / state |
|---|---|
| Source review | Baseline comparison, setting registry, build feature definitions, rates, OSD coordinates, names, and file structure |
| O4 activation | Complete, as the pilot reported on 2026-10-12; DJI firmware version not recorded |
| Required CLI settings | Confirmed by the [settings readback](<dumps/BTFL_cli_METEOR75_PRO_20261012_193623_BETAFPVG473 - settings check.txt>) on 2026-10-12 |
| CLI syntax validation | Complete; corrected input, batch restart, save, and matching capture after USB restart on 2026-10-12 |
| Accelerometer calibration | Pilot confirmed successful calibration, correct roll/pitch tilt responses, and return to level on 2026-10-12 |
| Bench verification | CH1–CH9, modes, adjustments, and correct radio/OSD battery indication confirmed on 2026-10-12; remaining [checks](SETUP.md) pending |
| Flight verification | Stock felt perfect outdoors on 2026-10-14; motors okay and video very good. Outdoor Cine/Park and Angle/Acro observations pending. |

No software build or aircraft simulator ran.
The file checks do not prove that the actual CLI accepts the file or that the aircraft flies correctly.

The pilot reported an already-configured binding phrase on 2026-10-12.
The pilot confirmed correct CH1–CH4 responses on 2026-10-12.
The pilot also confirmed SA/SB/SF/SE/SC channels, switch positions, and momentary/latching behaviour that day, before configuration application.
After application, the pilot confirmed the mode and adjustment ranges respond correctly on 2026-10-12.

The pilot reported a first flight and correct battery indication on the radio and OSD on 2026-10-12.
This confirms battery telemetry to the R1 and the OSD battery element.
The pilot confirmed flights on Stock and Cine.
Park and the remaining hardware observations are unrecorded.
Individual motor results remain open.
The pilot skipped the link-loss bench test on 2026-10-14; the actual failsafe response remains untested.

## Indoor flight observations — 2026-10-12

The pilot preferred Stock on the first indoor flight; Cine felt less satisfactory on the second battery.
Both flights used LAVA II 580 mAh packs.
The pilot also uses LAVA II 680 mAh packs, but that pack type was not part of this comparison.
The main reported difficulty was limited usable throttle stick travel within the available indoor height.
The pilot considered greater caution during the first flight as a possible influence.

The saved configuration gives Stock, Cine, and Park identical linear throttle curves.
The source at `eb2bb5a33`, [rc.c lines 824–859](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/rc.c#L824), defines that mapping.
The pilot confirmed Stock outdoors on 2026-10-14; Cine/Park outdoor observations remain pending.
Current settings remain unchanged. Any later rate or throttle adjustment will use a separate change.

## Flight observations — 2026-10-14

The pilot reported no observed battery problems during the day's flights.
In response to the heat question, the pilot reported that the motors were okay.
No measured motor temperatures were supplied.
The pilot described the video as very good and strongly preferred the wide camera and stabilization over the Meteor v1.

The pilot confirmed that Stock felt "perfect" outdoors.
Pack capacities and Angle/Acro behaviour remain unrecorded for that day.
Outdoor Cine/Park observations remain pending.
Keep the current rate and throttle settings.
Any later rate or throttle adjustment will use a separate OpenSpec change.

## CLI application progress

The pilot reported these results on 2026-10-12:

| Block | Commands | Result |
|---|---|---|
| 1 | Batch/reset, board, features, serial, and beacons | Accepted without errors |
| 2 | AUX modes and SC adjustment ranges | Accepted without errors |
| 3 | Hardware, filters, and battery settings | Last command first reported UNKNOWN COMMAND; retry accepted; CLI readback confirms `simplified_gyro_filter_multiplier = 125` |
| 4 | First OSD settings | Accepted without errors |
| 5 | Remaining OSD settings and craft name | Accepted without errors |
| 6 | PID profile 0 name, D-term filters, and P/I/D/F gains | Accepted without errors |
| 7 | Remaining GF 1811 PID settings | Accepted without errors |
| 8 | Rate profile 0, Pro II Stock | Accepted without errors |
| 9 | Rate profile 1, Cine | Accepted without errors |
| 10 | Rate profile 2, Park | Accepted without errors |

All configuration blocks are entered.
After the final save instruction, the pilot supplied a Configurator warning that the accelerometer is enabled but not calibrated.
The pilot then reported successful accelerometer calibration on 2026-10-12.
The pilot also confirmed correct roll/pitch tilt responses and return to level that day.
The 2026-10-12 19:59:33 capture matches the saved configuration after USB restart.
CLI syntax validation is complete after the corrected input and batch restart.

The corrected value is confirmed. The pilot reported the batch end/start sequence accepted on 2026-10-12.
The batch error reset is complete. The saved configuration capture confirms the final selections and persistence.
At the recorded commit, [cli.c lines 4241–4262](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/cli/cli.c#L4241) resets batch flags through `batch end`.
A following `batch start` starts a new error check without a defaults reset or a save.

## Saved configuration comparison — 2026-10-12

The pilot supplied [this capture](<dumps/BTFL_cli_METEOR75_PRO II_20261012_195933_BETAFPVG473 - current.txt>) after USB restart and calibration.
The comparison examined all 134 explicit `set` values in the reusable file.
All match the capture or a verified firmware default; 28 default-valued settings are absent from the diff as expected.
Those omissions are the explicit CRSF value, rate types, stock throttle values, and Stock axis values.
The explicit default UART3 serial line is also absent as expected.

All feature, beacon, serial, AUX, and adjustment commands match, with that UART3 default omission.
The captured PID tune, filters, hardware values, and all 31 OSD positions match.
The final selections are PID profile 0 and rate profile 0.
The capture adds the actual-aircraft calibration `-29,5,23,1`.
Identity/signature values are redacted. Comments and section order do not change the settings.
No unexplained configuration difference remains.

Status reports RX rate 82, BMI270 gyro/accelerometer, and the MSP 53 x 20 canvas.
It reports no battery and the flags `NOPREARM CLI MSP DSHOT_TELEM`.
This comparison establishes saved settings. Later pilot reports establish mode/adjustment response, a first flight, and correct battery indication.
The remaining hardware checks and flight details still require their own observations.

## Status and failsafe readback — 2026-10-14

The pilot supplied a [status capture](<dumps/BTFL_cli_METEOR75_PRO II_20261014_190858_BETAFPVG473 - status check.txt>).
It contains `status`, `get profile_name`, and `get failsafe`.
It confirms PID profile 0 (`GF 1811`) and rate profile 0 (`Stock`).
The saved failsafe procedure is `DROP`, with `failsafe_delay = 15`.

Status reports 0.71 V, `0S battery - NOT PRESENT`, and RX rate 0.
The flags are `RXLOSS NOPREARM CLI MSP DSHOT_TELEM`.
The pilot confirmed that only the laptop USB connection powered the aircraft during this capture.
No battery was connected. The radio state at capture remains unconfirmed.
This capture does not establish battery detection, motor telemetry, or the actual failsafe response.
The complete configuration capture from 2026-10-12 remains the sole `current` capture.

The pilot also reported flights on 2026-10-14 with no observed battery problems.
Pack capacities remain unrecorded; the later flight report confirms Stock outdoors.
The later battery-powered status confirms direct 1S detection.
The remaining bench observations remain pending.

### Battery-powered status — 2026-10-14

The pilot pasted [this status output](<dumps/BTFL_cli_METEOR75_PRO II_20261014_191538_BETAFPVG473 - battery status.txt>) at 17:15:38 UTC.
It reports `3.82V (1S battery - OK)`.
The flags are `RXLOSS NOPREARM CLI MSP`; `DSHOT_TELEM` is absent.
RX rate remains 0. The pilot confirmed that the R1 was off during this capture.
The earlier channel observations and flights establish receiver operation with the R1 on.
This confirms 1S detection and absence of the DSHOT_TELEM flag with battery power.
It does not establish individual motor order, direction, or telemetry results.

### PREARM and arm/disarm — 2026-10-14

The pilot confirmed that the motors remained stopped after an ARM attempt without SF PREARM.
The guided procedure required a fresh boot, removed propellers, battery power, and no USB connection.
The pilot confirmed the normal SF/SA arm/disarm sequence through the reported flights and response to the follow-up question.
No separate measurement of motor stop time was supplied.

### OSD and SC selection — 2026-10-14

The pilot confirmed that the OSD matches the v1 layout and that SC displays Stock / Cine / Park correctly.
No OSD problems were reported.
The 2026-10-12 saved configuration capture confirms the rate values and identical stock throttle settings for these profiles.
Tasks 5.3 and 5.7 are complete from these observations and the saved-value comparison.
This confirms Park selection; a Park flight report remains pending.

## Baseline comparison

The supplied [baseline](<dumps/BTFL_cli_METEOR75_PRO_20261012_184633_BETAFPVG473 - baseline.txt>) retains the original configuration and status output.
Only the board identity/signature values were redacted.
The accelerometer calibration remains in this capture as an observation of this aircraft.
The reusable configuration excludes that calibration and requires a new calibration after application.

| Area | Review result |
|---|---|
| PID profile 0 | Every captured `GF 1811` setting matches, including P/I/D/F, D-max, feedforward, dynamic idle, and TPA |
| Filters / orientation | Every captured value matches, including board yaw -90 degrees |
| Battery / current meter | Every captured value matches; no v1 threshold or scale was transferred |
| Motor settings | Every captured value matches |
| Features / beacons | Captured TELEMETRY, LED_STRIP, OSD, RX_LOST, and RX_SET commands match |
| Serial ports | Captured UART2 and UART4 assignments match; UART3/CRSF defaults are explicit |
| Failsafe | No failsafe override was added; the same firmware defaults still apply |
| AUX | The planned v1 mode layout replaces the baseline HORIZON and CH7 TURTLE assignments |
| SC | Three adjustment ranges select Stock / Cine / Park |
| OSD positions | All 31 position values match the older Meteor configuration; every coordinate fits the captured 53 x 20 canvas |
| OSD alarms | The baseline RSSI-dBm alarm of -99 remains unchanged |
| Names | Craft name is `Meteor75 Pro II`; rate names are `Stock`, `Cine`, and `Park` |
| File boundaries | `batch start`, `defaults nosave`, and final `save` are present |
| Final selections | PID profile 0 and rate profile 0 |
| Board identity / calibration | No identity, signature, accelerometer calibration, or trim values in the reusable file |

## Rates and throttle

The firmware source uses Actual rates with a soft centre and a nonlinear curve.
Zero configured expo does not make Actual rates linear.
The [defaults, controlrate_profile.c lines 42–67](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/controlrate_profile.c#L42) supply Stock.
The [curve, rc.c lines 228–237](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/rc.c#L228) supplies the unit conversion and calculation.

The exact throttle-hover CLI name is established by [parameter_names.h line 53](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/parameter_names.h#L53):

```c
#define PARAM_NAME_THR_HOVER "thr_hover"
```

The [setting registry, settings.c lines 1091–1120](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/cli/settings.c#L1091) exposes the rate and throttle settings.
Each selected profile explicitly uses the same stock throttle values.
The review confirmed every specified axis value for Stock, Cine, and Park.
The [rate adjustment selector, rc_adjustments.c lines 810–821](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/rc_adjustments.c#L810) maps three switch positions to profiles.
The adjustment function is number 12 in [rc_adjustments.h lines 29–43](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/rc_adjustments.h#L29).

## Receiver, modes, and failsafe

The [board config at revision 1359bbe, lines 91–96](https://github.com/betaflight/config/blob/1359bbe/configs/BETAFPVG473/config.h#L91) supplies UART3 / CRSF defaults.
The reusable file pins those defaults explicitly.
The [serial defaults, serial.c lines 258–291](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/io/serial.c#L258) confirm all four UART3 baud fields.
It does not alter receiver wiring.

The [mode table, msp_box.c lines 49–85](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/msp/msp_box.c#L49) supplies ARM, ANGLE, BEEPER, TURTLE, and PREARM IDs.
The [CLI parsers, cli.c lines 1186–1245 and 1711–1800](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/cli/cli.c#L1186) accept the AUX and adjustment command structures.
The review confirmed every AUX channel, mode ID, range, and adjustment argument.
The pilot confirmed PREARM refusal and normal SF/SA arm/disarm operation on 2026-10-14.
The [PREARM condition, core.c lines 392–397](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/core.c#L392) requires the configured mode before ARM.

The [failsafe defaults, failsafe.c lines 71–85](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/flight/failsafe.c#L71) select `DROP`.
The source default stage-1 delay is 15 units of 100 milliseconds.
The setup guide requires actual saved-value readback and a props-off link-loss check.
The 2026-10-14 readback confirms saved `DROP`.
The pilot requested that the link-loss bench test be skipped that day.
No observed failsafe response is recorded. Task 5.6 remains unchecked.

## OSD build features

The [build record](https://build.betaflight.com/api/builds/0fc940a951a76ec788851f939db8ed94/json) reports a successful build for `BETAFPVG473`.
Its request includes `USE_OSD_HD`, `USE_SERIALRX_CRSF`, `USE_TELEMETRY_CRSF`, and `USE_VTX`.
The record identifies the same key that the aircraft reports.
The request's release label is `2025.12.4`; the source commit comes from the aircraft's version header.

At `eb2bb5a33`, [common_pre.h lines 383–433](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/target/common_pre.h#L383) enables profile names and the OSD features.
HD OSD enables MSP DisplayPort, OSD profiles, and stick overlays.
The [OSD registry, settings.c lines 1571–1684](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/cli/settings.c#L1571) exposes all 31 transferred position names.
The [encoding, osd.h lines 56–89](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/osd/osd.h#L56) defines visibility flags and HD coordinates.

No requested layout element was omitted during source review.
The 2026-10-12 19:36:23 capture confirms the required `get` checks on the actual build.
It confirms throttle hover 50, profile-name support, artificial-horizon positions, stick overlays, rate-name position, and VTX-temperature position.
The pilot confirmed the OSD layout and all three rate names in the goggles on 2026-10-14.
An unexpected missing setting or missing visible element remains a failure to examine, not a verified exception.

## Expected round-trip differences

A post-application `diff all` can omit settings that equal the recorded firmware defaults.
The reusable file pins them to make the chosen values explicit.
Use `get` and the active profile selector to distinguish a default omission from a dropped paste line.

| Pinned default | Expected omission / readback |
|---|---|
| UART3 SERIAL_RX / CRSF | `serial UART3 64 ...` and `serialrx_provider = CRSF` can be absent from the diff |
| `rates_type = ACTUAL` | Can be absent from all three selected profiles |
| Stock axis settings | Centre values 7, max values 67, and expo values 0 can be absent from profile 0 |
| Throttle settings | Midpoint 50, expo 0, hover 50, limit OFF, and limit percent 100 can be absent from each profile |
| Empty profiles | Default-only PID profiles 1–3 and unused rate profile 3 contain no setting overrides |
| Calibration | The new actual-aircraft calibration differs from the reusable file's deliberate omission |
| Identity / comments | Raw identity/signature values require redaction; comments are not configuration values |

The selected rateprofile names, Cine/Park rotation overrides, AUX lines, and adjustment ranges must match.
Preserved tune and hardware values must match the baseline.
Record any other difference before the configuration receives a verified status.
