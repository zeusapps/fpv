# Proposal

## Why

The new Meteor75 Pro II O4 Wide needs the familiar Meteor75 Pro controls and OSD layout on the Oxbot R1.
The pilot wants to compare the Pro II stock rates with Cine and Park, with the stock throttle curve on each profile.

## What Changes

- Add a separate `meteor75-pro-ii/` aircraft folder with a dated baseline capture and an ELRS configuration.
- Preserve the captured `GF 1811` tune, filters, motor settings, board orientation, and receiver/video configuration.
- Set CH5 to ARM, CH6 to ANGLE / ACRO / TURTLE, CH7 to PREARM, and CH8 to BEEPER.
- Set SC / CH9 low, middle, and high to Pro II Stock, Cine, and Park, respectively.
- Use the Pro II stock throttle curve and full throttle on all three rate profiles.
- Transfer the supported v1 OSD positions and visibility to the Pro II HD canvas.
- Add setup, binding, and verification instructions for the Oxbot R1.
- Add O4 Air Unit activation instructions and a pilot verification task before goggles and OSD checks.
- Update the fleet index, radio links, OpenSpec aircraft context, and handoff with the new aircraft and its verification state.

## Capabilities

### New Capabilities

- `meteor75-pro-ii/flight-config`: Preserve the Pro II baseline and define its controls, rate profiles, throttle curve, OSD, and verification evidence.

### Modified Capabilities

None. The existing `radio/channel-mapping` requirements already cover the Oxbot R1 assignments and per-aircraft links.
The older `meteor75-pro/flight-config` capability remains specific to that aircraft and Betaflight 4.5.1.

## Impact

Implementation will add `meteor75-pro-ii/M75_PRO_II_ELRS_V1.txt`, aircraft documentation, and redacted captures under `meteor75-pro-ii/dumps/`.
It will update `README.md`, `HANDOFF.md`, relevant radio documents, and the aircraft inventory in `openspec/config.yaml`.
The source capture reports Betaflight `2025.12.5-alpha`, firmware commit `eb2bb5a33`, target `BETAFPVG473`, and the BMI270 gyro.
This change does not flash flight-controller firmware, retune the aircraft, add GPS Rescue, or create an SBUS variant.
The pilot will activate the O4 Air Unit through DJI Assistant 2 with their own DJI account.
Source review, CLI syntax validation, bench verification, and flight verification will have separate records.
