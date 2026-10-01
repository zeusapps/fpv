# radio/channel-mapping Specification

## Purpose
Any transmitter in the fleet must deliver every AUX function an aircraft's committed config uses,
on a physical control of the right type, with each channel proven on the Betaflight Receiver tab
rather than assumed from the radio's own screen. The aircraft config is the fixed side; each radio
is fitted to it.

## Requirements

### Requirement: A radio's channel assignment SHALL be derived from the aircraft's committed config

The source of truth for which channel does what is the `aux` and `adjrange` lines in the aircraft's
committed `.txt` config, plus any `aux` line a document in that aircraft folder records as applied
(the Pavo20's GPS Rescue line, `aux 6 46 5 1700 2100 0 0`, lives in `pavo20-pro-ii/FAILSAFE.md`
and is not in `PAVO20PRO2_ELRS_V1.txt`). A radio document MUST state which physical control drives
each channel. It MUST NOT restate the mode ranges; it links to the aircraft's channel table
(`pavo20-pro-ii/BINDING_GUIDE.md`, `meteor75-pro/README.md`). This extends the existing
`radio/gpsqr-widget` rule against restating per-aircraft settings to every radio.

The falsifying observation: a function listed in the aircraft's channel table that has no control
assigned in the radio's document, or a control assigned to a channel the aircraft does not read.

#### Scenario: Radio assignment covers the aircraft

- **WHEN** the radio's assignment table is compared with the aircraft's `aux` and `adjrange` lines
- **THEN** every channel those lines read has exactly one control assigned, and no function is
  described by value rather than by link

#### Scenario: Aircraft config changes

- **WHEN** an aircraft's `aux` line moves a function to a different channel
- **THEN** every radio document that assigns that channel is revisited in the same change

### Requirement: Each function SHALL sit on a control of the type its ranges require

The control type follows from the ranges the function uses:

| Function | Required control |
|---|---|
| ARM | 2-position, latching |
| A channel read in three bands (modes on CH6, rate profile on CH9) | 3-position |
| PREARM | momentary, or 2-position |
| BEEPER | any 2-position |
| GPS RESCUE | 2-position, latching |

A 2-position control on a three-band channel does not raise an error; one band becomes silently
unreachable. Where the ELRS link sends CH5 as a single bit, a 3-position source on CH5 collapses to
two states — see `radio/README.md`, *What each Full-Res switch mode actually transmits*, read off
ExpressLRS 3.5.6 `src/lib/OTA/OTA.cpp`.

GPS Rescue MUST NOT sit on a momentary control: rescue would end the moment the control is
released.

#### Scenario: Three-position channel

- **WHEN** the CH9 control is moved through each position with the aircraft connected
- **THEN** the Receiver tab shows three distinct values, each inside a different band of that
  aircraft's `adjrange` / `aux` lines

#### Scenario: Latching control released

- **WHEN** the GPS Rescue control is operated once and released
- **THEN** AUX 6 stays above 1700 until the control is operated again

### Requirement: GPS Rescue SHALL be assigned to a control that needs a deliberate reach

GPS Rescue MUST NOT be assigned to a control the pilot's hand rests on during normal flight, such
as a rear shoulder paddle. An accidental rescue hands control to a feature that on the Pavo20 Pro II
is configured and has never succeeded in the air: its one field trigger, on 2026-09-03, disarmed
and dropped the quad (`HANDOFF.md`). A mis-pressed beeper costs nothing; a mis-pressed rescue does.

This holds even where it makes a radio's layout differ from the V12 MAX. On the Oxbot R1 it puts
rescue on SD, a top toggle, rather than on a paddle, which is where copying the V12's button would
have put it.

The falsifying observation: the rescue control can be operated with the hands in the normal flying
grip, without moving a thumb or finger off the sticks or grip.

#### Scenario: Normal grip

- **WHEN** the pilot holds the radio in the flying grip and squeezes or brushes every rear control
- **THEN** AUX 6 does not change on the Receiver tab

### Requirement: The link settings SHALL carry every channel the aircraft uses

The radio's ELRS packet rate and switch mode MUST together transmit every channel the aircraft
reads. For the Pavo20 Pro II that includes CH10.

A channel that does not arrive shows as a bar that does not move, not as a missing channel. At
Betaflight `2025.12.2`, `rxInit` presets every channel to `midrc`
(`src/main/rx/rx.c:308`, `rcData[i] = rxConfig()->midrc;`) and only channels the receiver
delivers are overwritten. **A channel parked at exactly 1500 while its control is moved is the
signature of a channel the link never carried.** At ExpressLRS 3.5.6 the `8ch` Full-Res switch
mode never sends CH10, which is how the V12 lost the rescue switch until 2026-09-03; the standard
(non-"Full") packet rates carry up to CH12 in either switch mode. Where a radio does not expose
Switch Mode, as the Oxbot R1's ELRS menu does not, it MUST use a standard packet rate.

#### Scenario: CH10 on the Pavo20

- **WHEN** the rescue control is operated with the Pavo20 connected and the Receiver tab open
- **THEN** AUX 6 moves between about 1000 and about 2000, and the GPS RESCUE mode lights on the
  Modes tab

#### Scenario: Channel not carried

- **WHEN** a control is moved and its AUX bar reads exactly 1500 throughout
- **THEN** the assignment is not accepted, and the link settings are checked before the mapping

### Requirement: A radio-side throttle cut SHALL NOT stand in for disarm

A radio feature that forces the throttle channel to minimum (the Oxbot R1's *Throttle Lock*) MUST
be left disabled, and MUST NOT be described anywhere in this repo as a way to stop the motors.
CH5 ARM is the only control that stops them.

At Betaflight `2025.12.2` a disarmed quad sends `DSHOT_CMD_MOTOR_STOP`
(`src/main/drivers/dshot.c:63`), while an armed quad at minimum throttle is held at
`DSHOT_MIN_THROTTLE + motorIdlePercent * DSHOT_RANGE` (`dshot.c:70`) — motor idle, not stop. With
dynamic idle active that floor is lowered to allow zero drive
(`src/main/flight/mixer_init.c:361`), but the dynamic idle controller then holds a minimum RPM
instead. Either way, throttle at minimum while armed means props turning.

The falsifying observation: with props off and the aircraft armed, engaging the radio's throttle
cut leaves the motors spinning.

#### Scenario: Throttle cut engaged while armed

- **WHEN** the aircraft is armed on the bench, props off, and the radio's throttle cut is engaged
- **THEN** the motors keep spinning at idle, and only moving CH5 to disarm stops them
