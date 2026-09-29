## Purpose

Governs what the Pavo20 Pro II does when the control link is lost, what evidence is required
before GPS Rescue may become that response, and the thrust and geometry preconditions a rescue
depends on for a 2.2" ducted cinewhoop with very little thrust margin.

## ADDED Requirements

### Requirement: The failsafe procedure SHALL remain DROP until a rescue has been flown successfully

`failsafe_procedure` MUST stay at `DROP` until GPS Rescue has returned the aircraft and descended
near the pilot, on this airframe, on more than one attempt. Configuration alone SHALL NOT be
treated as qualification.

At Betaflight `2025.12.2` this is also the firmware default —
`.failsafe_procedure = FAILSAFE_PROCEDURE_DROP_IT` (`src/main/flight/failsafe.c:78`) — so the
requirement is satisfied by the setting being **absent** from a `diff`, not by a line asserting it.

The asymmetry is the whole reason: `DROP` fails by cutting motors, so the aircraft falls where it
already was. GPS Rescue fails by flying under power in a direction nobody chose. A rescue that has
not been flown is not a safer option than dropping, it is an untested one, and on 2026-09-03 the
first attempt on this aircraft ended with the motors stopped and the quad on the ground.

#### Scenario: Aircraft has not yet flown a successful rescue

- **WHEN** `get failsafe_procedure` is run on the aircraft
- **THEN** it returns `DROP`, and no committed config contains a line setting it to anything else
  outside the separately gated arming file

#### Scenario: Radio switched off in flight before qualification

- **WHEN** the pilot switches the transmitter off with the aircraft armed and airborne
- **THEN** the motors stop and the aircraft falls, rather than attempting to fly home

### Requirement: The rescue configuration SHALL be split so the arming line cannot be applied early

GPS Rescue configuration MUST be delivered as two files: the tuning parameters, which are safe to
apply at any time, and a separate file containing only `set failsafe_procedure = GPS-RESCUE`. A
single file containing both MUST NOT exist.

The two halves carry opposite risk. The parameters only change what a rescue the pilot deliberately
triggers does, and they make it gentler than the firmware defaults — there is a positive reason to
apply them before testing, because the default `gps_rescue_ascend_rate` of `750` cm/s
(`src/main/pg/gps_rescue_multirotor.c:41`) demands a 7.5 m/s climb this airframe cannot produce, so
testing without them tests a different aircraft. The arming line changes what happens when nobody
is holding the sticks.

Bundling them forces a choice between testing on untuned values and arming an untested failsafe.

#### Scenario: Tuning applied before any rescue has been flown

- **WHEN** the tuning file is pasted and saved
- **THEN** `get gps_rescue_ascend_rate` returns the tuned value and `get failsafe_procedure` still
  returns `DROP`

#### Scenario: Arming file is applied

- **WHEN** the arming file is pasted
- **THEN** `get failsafe_procedure` returns `GPS-RESCUE`, and any other result means the paste did
  not take and the aircraft is still dropping

### Requirement: The autopilot hover throttle SHALL match the airframe's measured hover throttle

`ap_hover_throttle` MUST be set from an observed hover on this aircraft, not left at the firmware
default, before a rescue is flown.

It is the throttle the aircraft is commanded at the instant a rescue begins. At `2025.12.2` the
altitude controller computes
`throttleOffset = altitudeP + altitudeI - altitudeD + altitudeF + hoverOffset` where
`hoverOffset = hoverThrottle - PWM_RANGE_MIN` (`src/main/flight/autopilot_multirotor.c:195-205`).
`RESCUE_INITIALIZE` calls `resetAltitudeControl()`, zeroing the integrator
(`src/main/flight/gps_rescue_multirotor.c:209` and `autopilot_multirotor.c:163-165`), and the
target altitude is set to the current altitude while idle, so the P term starts near zero.
Commanded throttle at rescue onset is therefore approximately `ap_hover_throttle` alone.

The default is `1275` (`src/main/pg/autopilot_multirotor.c:36`), i.e. 27.5%. This airframe's
throttle curve places its hover point at 34% (`thr_hover = 34`, the y-coordinate of the hover
point per `src/main/fc/rc.c:826-838`), around `1340`. A rescue therefore begins roughly 6.5% below
hover.

That is not merely a sag. Falling short of the commanded climb is itself a failure condition, and
one that **ignores `gps_rescue_sanity_checks` entirely**: in `RESCUE_ATTAIN_ALT`, if achieved
altitude change is under half the target change, a counter increments once per second and at ten
seconds forces `RESCUE_LANDING`, which enables impact detection and aborts — disarming — after a
further ten (`gps_rescue_multirotor.c:434-460`, `:826-838`). A quad that cannot climb is thus
brought down by the rescue itself.

#### Scenario: Hover throttle is measured rather than assumed

- **WHEN** the aircraft is held in a steady hover and the OSD throttle percentage is read
- **THEN** `ap_hover_throttle` is set to that percentage expressed on the 1000–2000 scale, and a
  later hover shows the aircraft holding altitude without the pilot's stick drifting upward

#### Scenario: A rescue is triggered with the correct hover reference

- **WHEN** GPS Rescue is engaged in flight above the minimum start distance
- **THEN** the aircraft gains altitude within the first few seconds rather than sinking, which is
  the observation that fails if the hover reference is too low

### Requirement: A rescue SHALL be triggered beyond the minimum start distance during testing

A rescue intended to demonstrate return-to-home MUST be triggered at a distance greater than
`gps_rescue_min_start_dist`. Closer triggers exercise different code paths and MUST NOT be read as
rescue failures.

At `2025.12.2`, `RESCUE_INITIALIZE` branches three ways
(`src/main/flight/gps_rescue_multirotor.c:717-742`):

- Distance below 5 m **and** below the landing altitude sets `RESCUE_ABORT`, which disarms
  deliberately (`:834-838`). The landing altitude is `getAltitudeCm() < 100 * landingAltitudeM`
  (`src/main/flight/autopilot_multirotor.c:386-389`) with `ap_landing_altitude_m` defaulting to `4`
  (`src/main/pg/autopilot_multirotor.c:36`).
- Distance below `gps_rescue_min_start_dist` raises the return altitude to at least 10 m and
  pitches the aircraft **forward, away from home**, until it is beyond that distance.
- Otherwise the normal climb, rotate, fly home, descend sequence runs.

Only the third demonstrates anything about returning home. The middle case in particular looks
like a malfunction — the aircraft departs — and is correct behaviour.

#### Scenario: Rescue triggered close in and low

- **WHEN** the rescue switch is flipped within 5 m of home and below 4 m altitude
- **THEN** the aircraft disarms immediately, and this is recorded as the designed abort rather than
  as a rescue failure

#### Scenario: Rescue triggered at a qualifying distance

- **WHEN** the rescue switch is flipped beyond `gps_rescue_min_start_dist` from home
- **THEN** the aircraft climbs, rotates toward home, flies back and begins descending, and each
  phase is observed rather than inferred from where it ended up

### Requirement: A rescue attempt SHALL be recorded by instrumentation rather than recollection

Before a rescue is flown, `debug_mode` MUST be set so the attempt is logged. An outcome described
only from memory SHALL NOT be used to accept or reject a rescue configuration.

At `2025.12.2` the rescue writes its own diagnostics: max altitude to `DEBUG_RTH` slot 0,
`failure * 10 + phase` to slot 2, and `secondsFailing * 100 + secondsLowSats` to slot 3
(`src/main/flight/gps_rescue_multirotor.c:850`, `:474-475`). `DEBUG_RTH` is selectable as `RTH`
(`src/main/build/debug.c:66`). The altitude controller separately logs commanded throttle and each
PID term under `DEBUG_AUTOPILOT_ALTITUDE` (`autopilot_multirotor.c:206-217`).

This exists because the 2026-09-03 attempt produced no record. Whether the motors stopped in the
air or on impact, which phase was active, and whether the aircraft ever climbed are all
unrecoverable, and each points at a different cause.

#### Scenario: A rescue attempt is flown

- **WHEN** the rescue switch is used in flight
- **THEN** the blackbox log for that flight contains the `RTH` debug fields, and the phase and
  failure code at the moment the aircraft descended can be read from it

#### Scenario: An attempt was not instrumented

- **WHEN** a rescue attempt was flown with `debug_mode` set to anything else
- **THEN** its outcome is recorded as an observation needing repetition, not as evidence for or
  against the configuration
