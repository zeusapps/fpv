## Purpose

The pin and UART constraints of the BetaFPV Cube G4 board as fitted in this aircraft, expressed as
rules a config or a rebuild must not violate. It exists because the original GPS fault was a wiring
conflict that looked like a software problem and cost a great deal of time to isolate.

## ADDED Requirements

### Requirement: GPS SHALL NOT share a UART with the O4 air unit SBUS output

The GPS module MUST NOT be wired to, and MUST NOT be configured on, the pad carrying the DJI O4 air
unit's SBUS output. On the `BETAFPVG473_V3` board that pad is `R1` (`PA10`, UART1 RX).

The board routes the air unit's SBUS output to `R1` internally. Soldering the GPS module's TX to
that same pad — which BetaFPV's own GPS guide instructs, because it is written for a different
board — puts two push-pull drivers on one net. Neither is damaged, and the fault is intermittent by
nature: GPS works perfectly with the air unit unplugged, and produces bit-corrupted NMEA the moment
it is connected.

This was diagnosed by continuity-testing the air unit connector against `R1`, after several
plausible software explanations had been proposed and disproved. `pavo20-pro-ii/GPS_SETUP.md` has
the full write-up.

The rule is stated in terms of the *conflict* rather than the current wiring, because the current
wiring is one solution and not the only one. As rewired on 2026-09-01 the GPS is on UART2 (`T2` =
`PA2`, `R2` = `PA3`) and `R1` is left to the air unit, with the LED strip moved to `T1` (`PA9`).

Falsifying observation: a config in which the serial function bitmask for UART1 includes the GPS
bit (`2`) while the air unit is fitted.

#### Scenario: GPS configured onto the air unit UART

- **WHEN** a config sets the GPS function on UART1 on a board with the O4 air unit fitted
- **THEN** the config is rejected as violating this requirement, whatever the bench behaviour with
  the air unit unplugged

#### Scenario: Bench test that appears to pass

- **WHEN** GPS is tested on UART1 with the air unit disconnected
- **THEN** the result is not accepted as evidence, because the conflict only appears when the air
  unit is powered and driving the shared net

### Requirement: A config SHALL be verifiable against a capture of the aircraft it claims to describe

Every claim in this folder about which signal is on which pad MUST be checkable against the newest
capture in `dumps/`, and the capture MUST be the aircraft as flown.

The `resource`, `timer`, `dma` and `serial` blocks of a `diff all` are the authoritative record of
the wiring as the firmware sees it. Documentation that disagrees with them is wrong by definition,
because the aircraft flies on the firmware's view and not on the prose.

This is not hypothetical. Between 2026-09-01 and 2026-09-03 the only capture in `dumps/` was the
pre-rewire state, so the repo's own record still showed GPS on the contended UART1 — the exact
fault that had already been fixed in hardware. `pavo20-pro-ii/README.md` stated GPS was on UART1
for the same reason, and `GPS_SETUP.md` named the wrong profile for a 3S pack because the profiles
had been reordered after that text was written.

#### Scenario: Wiring documentation contradicts the newest capture

- **WHEN** a document states a pad or UART assignment that the newest `dumps/` capture contradicts
- **THEN** the document is corrected to match the capture, not the other way round

#### Scenario: Hardware is rewired

- **WHEN** any signal is moved between pads on the aircraft
- **THEN** a fresh `diff all` is captured into `dumps/` and the previous capture is retitled to say
  what state it recorded, so that exactly one capture is labelled as current
