# Meteor75 Pro II O4 Wide

BetaFPV Meteor75 Pro II, 1S whoop with the DJI O4 Wide Air Unit.
The pilot will use the Oxbot R1 with the familiar Meteor75 Pro controls and OSD layout.

## Aircraft baseline

The pilot supplied the baseline capture on 2026-10-12.
It contains `diff all` and `status` from this aircraft.
It is not a capture after application of the new configuration.

| Item | Evidence from the supplied capture |
|---|---|
| Target | `BETAFPVG473`, manufacturer `BEFH` |
| Firmware | `2025.12.5-alpha`, commit `eb2bb5a33`, MSP API 1.47 |
| Config revision | `1359bbe` |
| Gyro / accelerometer | BMI270 |
| Video | UART4, MSP + VTX_MSP; MSP OSD, 53 x 20 |
| Receiver | UART3 / CRSF board defaults; pilot confirmed CH1–CH4 responses on 2026-10-12 |
| PID profile | Profile 0, `GF 1811` |
| Motors | DSHOT300, bidirectional DShot, 12 poles |
| Packs in use | LAVA II 580 and 680 mAh; both reported indoor comparison flights used 580 mAh packs |
| Board yaw | `align_board_yaw = -90` |
| Battery ceiling / warning | `440` / `345`, as captured |
| Telemetry | Enabled |

The build key is `0fc940a951a76ec788851f939db8ed94`.
Its build request names `2025.12.4`; the aircraft's version header names `2025.12.5-alpha`.
Source references use the recorded firmware commit.

The configuration preserves the Pro II tune, filters, orientation, battery settings, receiver, video, telemetry, and failsafe settings.
It changes the mode assignments, rate profiles, OSD layout, and display names.
Do not apply the older Meteor configuration to this aircraft.

## Files

- [M75_PRO_II_ELRS_V1.txt](M75_PRO_II_ELRS_V1.txt) — reusable ELRS configuration for the Oxbot R1.
- [SETUP.md](SETUP.md) — O4 activation, radio connection, application, and hardware verification.
- [SOURCE_REVIEW.md](SOURCE_REVIEW.md) — source evidence, permitted differences, and verification state.
- [VERIFICATION.md](VERIFICATION.md) — change review and remaining tasks as of 2026-10-14.
- [Baseline capture](<dumps/BTFL_cli_METEOR75_PRO_20261012_184633_BETAFPVG473 - baseline.txt>) — supplied aircraft capture, with identity/signature values redacted.

The [current capture](<dumps/BTFL_cli_METEOR75_PRO II_20261012_195933_BETAFPVG473 - current.txt>) matches the configuration after USB restart and calibration.
It establishes the saved settings, not completion of the remaining bench or flight checks.
Keep exactly one `current` capture when later captures replace it.

## Switches

| Channel | Oxbot R1 | Low | Middle | High |
|---|---|---|---|---|
| CH5 / AUX1 | SA | Disarmed | — | ARM |
| CH6 / AUX2 | SB | ANGLE | ACRO | TURTLE |
| CH7 / AUX3 | SF, momentary | PREARM inactive | — | PREARM |
| CH8 / AUX4 | SE, latching | BEEPER inactive | — | BEEPER |
| CH9 / AUX5 | SC | **Stock** | **Cine** | **Park** |

The mode ranges are 1700–2100 for ARM, PREARM, BEEPER, and TURTLE.
ANGLE uses 900–1300 on CH6.
SC uses 900–1200, 1375–1675, and 1800–2100 on CH9.
Each SC position selects rate profile 0, 1, or 2, respectively.
The displayed rate name identifies the selection.

**Use the factory controls with care until the configuration is applied.**
The supplied baseline puts TURTLE on CH7 and HORIZON on CH6 middle.
It has no PREARM assignment or SC rate selection.

The R1's channel assignments match the existing fleet model.
See [Oxbot R1 setup](../radio/oxbot-r1/README.md) for radio settings.
The V12 MAX uses different physical controls for PREARM and BEEPER: SD and front button 3.
Pro II operation on the V12 MAX remains unverified.

## Rates and throttle

All three profiles use **Actual rates**.
Values below are centre sensitivity / maximum rate / expo, in the Configurator's displayed units.

| SC / profile | Roll and pitch | Yaw |
|---|---|---|
| Low / 0 **Stock** | 70 / 670 degrees per second / 0.00 | 70 / 670 degrees per second / 0.00 |
| Middle / 1 **Cine** | 40 / 450 degrees per second / 0.45 | 40 / 400 degrees per second / 0.40 |
| High / 2 **Park** | 50 / 600 degrees per second / 0.50 | 50 / 540 degrees per second / 0.45 |

Stock is the Pro II firmware-default rotation curve.
Cine and Park use the rotation values from the [older Meteor configuration](../meteor75-pro/M75_PRO_ELRS_V1.txt).
They use the **Pro II stock throttle curve**, not the older throttle curve.

Each profile has `thr_mid = 50`, `thr_expo = 0`, and `thr_hover = 50`.
Each has `throttle_limit_type = OFF` and `throttle_limit_percent = 100`.
The saved configuration selects Stock; SC determines the selection when the receiver link operates.

Stock commands more rotation at partial stick than the older Base profile.
At half roll/pitch stick, Stock commands approximately 185 degrees per second; older Base commands 122.
At full roll/pitch stick, Stock commands 670 degrees per second; older Base commands 720.
These are calculated commands, not measured flight results.
See [source review](SOURCE_REVIEW.md#rates-and-throttle) for the formula and evidence.

## Verification state

As of 2026-10-14:

The pilot requested [archival](../openspec/changes/archive/2026-10-14-configure-meteor75-pro-ii/) with the remaining checks documented.
Unperformed checks remain unverified. Keep the current rates and throttle curve.

| Stage | Result |
|---|---|
| Source review | Complete; see [SOURCE_REVIEW.md](SOURCE_REVIEW.md) |
| Binding phrase | Already configured, as the pilot reported on 2026-10-12; phrase not stored here |
| O4 activation | Complete, as the pilot reported on 2026-10-12; DJI firmware version not recorded |
| Goggles | DJI Goggles 3; pilot reported the link complete on 2026-10-12; firmware versions not recorded |
| Required CLI settings | Confirmed by the [settings readback](<dumps/BTFL_cli_METEOR75_PRO_20261012_193623_BETAFPVG473 - settings check.txt>) on 2026-10-12 |
| CLI syntax validation on the aircraft | Complete; corrected input, batch restart, save, and matching capture after USB restart on 2026-10-12 |
| Accelerometer calibration | Pilot confirmed successful calibration, correct roll/pitch tilt responses, and return to level on 2026-10-12 |
| Bench verification | CH1–CH9, modes, adjustments, and correct radio/OSD battery indication confirmed on 2026-10-12; remaining checks pending |
| Flight verification | Stock felt perfect outdoors on 2026-10-14; motors okay and video very good. Outdoor Cine/Park and Angle/Acro observations pending. |

The baseline has RX rate 0, no battery, and `RXLOSS CLI MSP DSHOT_TELEM` arming flags.
That observation does not establish a receiver fault or a motor telemetry fault.
The battery-powered checks in [SETUP.md](SETUP.md) must establish the actual state.

The current capture has RX rate 82 and no RXLOSS flag.
It stores `acc_calibration = -29,5,23,1` and selects PID profile 0 / rate profile 0.
Its flags are `NOPREARM CLI MSP DSHOT_TELEM`, with the battery disconnected.
The pilot then confirmed the mode and adjustment ranges respond correctly.

The pilot reported a first flight and correct battery indication on the R1 and OSD on 2026-10-12.
The pilot confirmed flights on Stock and Cine.
Park and Angle/Acro observations remain unrecorded.
Individual motor results remain open.
The pilot skipped the link-loss bench test on 2026-10-14.
The saved procedure is `DROP`; the actual failsafe response remains untested.

The [2026-10-14 status capture](<dumps/BTFL_cli_METEOR75_PRO II_20261014_190858_BETAFPVG473 - status check.txt>) confirms PID profile 0, Stock, and failsafe `DROP`.
It reports 0.71 V, no detected battery, RX rate 0, and an RXLOSS flag.
The pilot confirmed that only USB powered the aircraft during this capture, with no battery connected.
The pilot also reported flights on 2026-10-14 with no observed battery problems.

The [later battery-powered status](<dumps/BTFL_cli_METEOR75_PRO II_20261014_191538_BETAFPVG473 - battery status.txt>) reports 3.82 V and `1S battery - OK`.
It has no DSHOT_TELEM flag, but RX rate remains 0 with RXLOSS.
The pilot confirmed that the R1 was off during this capture.
The earlier channel observations and flights establish receiver operation with the R1 on.
The other bench checks remain open.

The pilot confirmed refusal to ARM without PREARM after the fresh-boot procedure on 2026-10-14.
The pilot also confirmed normal SF/SA arm/disarm operation through the reported flights and response to the follow-up question.

The pilot confirmed the OSD layout and Stock / Cine / Park display on 2026-10-14, with no reported OSD problems.
All three SC selections are confirmed. A Park flight report remains pending.

### Indoor flight observations — 2026-10-12

The pilot preferred Stock during the first indoor flight.
Cine felt less satisfactory on the second battery.
Both flights used LAVA II 580 mAh packs; the pilot also uses 680 mAh packs.
The main difficulty was precise throttle control within the available indoor height.
The pilot reported too little usable stick travel for that height range.

The pilot considered greater caution during the first flight as a possible influence.
The comparison did not include a change between 580 and 680 mAh pack types.
Stock and Cine have the same linear throttle curve; SC changes the rotation rates.
Current rates and throttle settings remain unchanged.
Any later rate or throttle adjustment will use a separate OpenSpec change.

### Flight observations — 2026-10-14

The pilot reported no observed battery problems.
In response to the heat question, the pilot reported that the motors were okay; no measured temperatures were supplied.
The pilot described the video as very good.
The pilot strongly preferred the wide camera and stabilization over the Meteor v1.
The pilot confirmed that Stock felt "perfect" outdoors.
The day's pack capacities remain unrecorded.

Outdoor Cine/Park observations remain pending.
Keep the current rate and throttle settings. Any later adjustment will use a separate OpenSpec change.
