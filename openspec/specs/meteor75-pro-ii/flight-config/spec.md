# Meteor75 Pro II flight configuration

## Purpose

Define a repeatable Meteor75 Pro II O4 Wide configuration for the Oxbot R1.
Preserve the aircraft baseline and define the controls, rate choices, throttle curve, OSD layout, and verification evidence.

## Requirements

### Requirement: The configuration SHALL preserve the Pro II baseline

The configuration MUST target `BETAFPVG473` with Betaflight `2025.12.5-alpha`, firmware commit `eb2bb5a33`, and the captured BMI270 hardware.
It MUST preserve the captured `GF 1811` PID profile, gyro/D-term filters, motor configuration, board orientation, and battery settings.
It MUST preserve the receiver, video, telemetry, and failsafe configuration.
The permitted changes are mode assignments, rate selection, the specified rate profiles, OSD positions/visibility, and aircraft/profile display names.
The configuration MUST finish with PID profile 0 and rate profile 0 selected.

Evidence: the pilot's `BTFL_cli_METEOR75_PRO_20261012_184633_BETAFPVG473.txt` contains the baseline `diff all` and `status`.
The configuration MUST NOT use the older aircraft's `GF 40mm` tune or Betaflight 4.5.1 assumptions.
Falsifying observation: a preserved setting differs from the baseline without a documented, approved scope revision.

#### Scenario: Review the configuration against its baseline

- **WHEN** the proposed configuration is compared with the dated baseline
- **THEN** only the permitted settings and deliberate omissions of board identifiers/calibration differ
- **AND** PID profile 0 contains the captured `GF 1811` tune

### Requirement: The Oxbot R1 SHALL retain the familiar control assignments

The aircraft MUST use these assignments:

| Channel | R1 control | Low | Middle | High |
|---|---|---|---|---|
| CH5 | SA | Disarmed | Not applicable | ARM |
| CH6 | SB | ANGLE | ACRO | TURTLE |
| CH7 | SF, momentary | PREARM inactive | Not applicable | PREARM |
| CH8 | SE, latching | BEEPER inactive | Not applicable | BEEPER |

The CH6 middle position MUST NOT activate HORIZON.
CH7 MUST NOT request TURTLE.
The pilot MUST prove these assignments on the Receiver and Modes tabs before flight.

At the recorded firmware version, [src/main/msp/msp_box.c, lines 49-85](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/msp/msp_box.c#L49) defines the mode IDs.
[src/main/fc/core.c, lines 392-397](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/core.c#L392) defines the PREARM arming condition.
Falsifying observation: SA arms without the required PREARM, SF requests TURTLE, or SB middle activates HORIZON.

#### Scenario: Operate the R1 mode controls

- **WHEN** the pilot operates SA, SB, SF, and SE with the aircraft connected
- **THEN** only the specified channels and mode ranges respond
- **AND** SF returns PREARM to inactive after release

#### Scenario: Verify the arming condition

- **GIVEN** the propellers are removed, throttle is at minimum, and all other arming conditions permit ARM
- **WHEN** the pilot attempts ARM without PREARM after a reboot
- **THEN** the aircraft refuses to arm
- **AND** SF followed by SA permits ARM, and SA low stops the motors

### Requirement: SC SHALL select Stock, Cine, and Park in that order

SC / CH9 low, middle, and high MUST select rate profiles 0, 1, and 2, respectively.
The displayed names MUST be `Stock`, `Cine`, and `Park`.
Documentation MUST identify `Stock` as Pro II Stock.
The following Actual-rate values MUST apply, in centre sensitivity / maximum rate / expo order:

| Profile | Roll and pitch | Yaw |
|---|---|---|
| 0 Stock | 70 / 670 degrees per second / 0.00 | 70 / 670 degrees per second / 0.00 |
| 1 Cine | 40 / 450 degrees per second / 0.45 | 40 / 400 degrees per second / 0.40 |
| 2 Park | 50 / 600 degrees per second / 0.50 | 50 / 540 degrees per second / 0.45 |

The stock values come from [src/main/fc/controlrate_profile.c, lines 42-67](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/controlrate_profile.c#L42) at `2025.12.5-alpha`, commit `eb2bb5a33`.
[src/main/fc/rc.c, lines 228-237](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/rc.c#L228) defines their units and curve.
The Cine and Park values come from `meteor75-pro/M75_PRO_ELRS_V1.txt`.
[src/main/fc/rc_adjustments.c, lines 606-617 and 810-821](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/rc_adjustments.c#L810) defines rate-profile selection at this firmware version.
Falsifying observation: any SC position selects the wrong profile or any profile has different rate values.

#### Scenario: Select each rate profile

- **WHEN** the pilot moves SC from low through middle to high
- **THEN** the active rate profile changes from Stock through Cine to Park
- **AND** the Rates tab values match the specified table

### Requirement: Every selected rate profile SHALL use the stock throttle curve

Profiles Stock, Cine, and Park MUST use throttle midpoint 50, throttle expo 0, and throttle hover 50.
Throttle limiting MUST be OFF, with throttle limit percent 100.
The older aircraft's midpoint 45 and expo 65 MUST NOT be transferred.

These defaults come from [src/main/fc/controlrate_profile.c, lines 46-65](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/fc/controlrate_profile.c#L42) at `2025.12.5-alpha`, commit `eb2bb5a33`.
Falsifying observation: a throttle value differs between the three selected profiles or from the stock defaults.

#### Scenario: Compare throttle settings across SC positions

- **WHEN** the three selected profiles are examined after the configuration is saved
- **THEN** their throttle settings are identical and match the specified stock values

### Requirement: The HD OSD SHALL retain the supported v1 layout

The configuration MUST transfer supported OSD positions and visibility from `meteor75-pro/M75_PRO_ELRS_V1.txt`.
It MUST use the captured MSP 53 x 20 canvas and preserve the O4 video connection.
The rate-profile name MUST be visible so the pilot can identify Stock, Cine, and Park.
Documentation MUST record each unavailable layout element and its evidence.
The layout transfer MUST NOT change battery or link alarm thresholds without an approved scope revision.

At `2025.12.5-alpha`, commit `eb2bb5a33`, [src/main/osd/osd.h, lines 56-89](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/osd/osd.h#L56) defines the position encoding and HD canvas.
[src/main/cli/settings.c, lines 1650-1684](https://github.com/betaflight/betaflight/blob/eb2bb5a33/src/main/cli/settings.c#L1650) shows conditional OSD elements.
Falsifying observation: a supported element has the wrong position/visibility, or the selected rate name is absent from the goggles.

#### Scenario: Examine the OSD in the O4 goggles

- **WHEN** the pilot examines the OSD and operates SC
- **THEN** supported elements match the v1 layout
- **AND** the displayed rate name matches the selected profile

### Requirement: O4 activation SHALL precede goggles and flight verification

The aircraft setup guide MUST include O4 Air Unit activation through DJI Assistant 2 (Consumer Drones Series).
It MUST require aircraft power and a USB data connection to the air unit's own USB-C port.
It MUST require propeller removal and airflow across the powered air unit for this bench procedure.
The pilot MUST use their own DJI account and complete the activation prompts.
The activation result MUST be recorded before goggles, OSD, or flight verification is marked complete.
Activation MUST NOT be confused with the ELRS receiver bind or the goggles link.
The documentation MUST NOT contain DJI credentials or claim activation from a Betaflight capture.

Source: DJI O4 Air Unit Series User Manual v1.0, [sections 2.1, 3.1, and 4.1](https://dl.djicdn.com/downloads/DJI_O4_Air_Unit_Series/UM/DJI_O4_Air_Unit_Series_User_Manual_v1.0_en.pdf), read 2026-10-12.
DJI's [activation support article](https://repair.dji.com/help/content?customId=01700011933&documentType=&lang=zh-CN&paperDocType=ARTICLE&re=CN&spaceId=17) also lists the O4 Wide Air Unit.
Falsifying observation: activation is incomplete, the guide uses only the flight-controller USB connection, or video verification lacks activation evidence.

#### Scenario: Activate a new O4 Air Unit

- **WHEN** the pilot follows the activation procedure with the air unit powered and connected to DJI Assistant 2
- **THEN** DJI Assistant 2 confirms successful activation, or the record states a specific failure
- **AND** goggles and flight verification remain incomplete if activation fails

#### Scenario: Use an air unit that is already activated

- **WHEN** the pilot confirms that the O4 Air Unit is already activated
- **THEN** the record includes that observation
- **AND** the pilot can proceed to the goggles link and OSD checks without a second activation

### Requirement: Reusable configuration SHALL exclude board identity and calibration

The reusable configuration MUST NOT contain `mcu_id`, `signature`, `acc_calibration`, `acc_trim_pitch`, or `acc_trim_roll` values.
The setup procedure MUST require accelerometer calibration on the actual, level aircraft after the configuration is applied.
It MUST require a matching Setup-tab attitude response before flight.
Falsifying observation: the reusable file contains a prohibited value, or flight proceeds without the required calibration and attitude check.

#### Scenario: Prepare the actual aircraft for flight

- **WHEN** the pilot completes the documented setup procedure
- **THEN** the accelerometer calibration comes from this aircraft
- **AND** the Setup model follows the aircraft's physical tilt and returns to level

### Requirement: Captures and verification records SHALL identify actual evidence

The aircraft folder MUST contain a dated baseline capture with `mcu_id` and signature values redacted.
A fresh capture MUST be requested after the pilot applies and saves the configuration.
Every difference MUST have an explanation, including settings absent from `diff all` because they equal firmware defaults.
The record MUST separate source review, CLI syntax validation, bench verification, and flight verification.
An unperformed hardware check MUST remain incomplete and marked unverified.
Falsifying observation: a verification claim lacks its corresponding aircraft observation or a capture difference has no explanation.

#### Scenario: Complete repository implementation before hardware checks

- **WHEN** configuration and documentation files exist but the pilot has not applied them
- **THEN** source review can be complete
- **AND** CLI syntax validation, bench verification, and flight verification remain incomplete

#### Scenario: Record a configuration round trip

- **WHEN** the pilot provides a fresh capture after application and calibration
- **THEN** it is compared with the configuration and each difference is recorded
- **AND** only observed results receive a verified status

### Requirement: Radio documentation SHALL link to aircraft-specific settings

The aircraft documentation MUST identify the R1 controls and link to the shared radio setup.
Shared radio documentation MUST link to the Pro II channel and rate tables.
It MUST NOT describe SC profile order as identical across the older Meteor and the Pro II.
Binding instructions MUST use the established fleet phrase procedure without a committed phrase or unnecessary receiver firmware changes.
Falsifying observation: radio documentation assigns the older Cine / Park / Base order to the Pro II or contains a binding secret.

#### Scenario: Use the established R1 channel assignments

- **WHEN** the pilot follows the radio and aircraft documentation
- **THEN** the physical channel assignments match the established R1 model
- **AND** the Pro II aircraft table supplies the Stock / Cine / Park order
