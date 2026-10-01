# Proposal

## Why

An Oxbot R1 has joined the fleet's radios, and it is being trialled against the HelloRadio V12 MAX
before either is chosen. It must fly the Pavo20 Pro II and the Meteor75 Pro with the same controls
doing the same things. The R1 runs OXBOT OS, not EdgeTX, so nothing in `radio/` carries across
as-is: there is no Lua, no logical switches, no ELRS Switch Mode setting, and it has six switches
where the V12 has more. Its switches also differ physically from the V12's, and a direct
copy of the V12 layout would put GPS Rescue on a shoulder paddle that sits under a finger for the
whole flight.

`radio/` is also written as though one radio flies everything ("One radio flies all three
aircraft"). There are now four — V12 MAX, Radiomaster Pocket, Oxbot R1, DJI RC3 — and the V12's
own switch assignment has never been written down, so "make it work like the V12" had no reference
to point at until it was recovered from the user on 2026-09-30.

## What Changes

- New `radio/oxbot-r1/README.md`: the R1's switch-to-channel assignment for both aircraft, the
  ELRS settings it needs, the R1 features to leave off, and a bench check that proves each channel.
- The R1 assignment, decided 2026-09-30:

  | CH | Function | V12 MAX | Oxbot R1 |
  |---|---|---|---|
  | CH5 | ARM | SA, 2-pos | SA, 2-pos |
  | CH6 | ANGLE / acro / TURTLE | SB, 3-pos | SB, 3-pos |
  | CH7 | PREARM | SD, momentary | SF, momentary paddle |
  | CH8 | BEEPER | front button 3 | SE, latching paddle |
  | CH9 | rate profile (+ LEDLOW on Pavo20) | SC, 3-pos | SC, 3-pos |
  | CH10 | GPS RESCUE (Pavo20 only) | front button 6 | SD, 2-pos toggle |

  CH10 deliberately does **not** follow the V12's control type — see `design.md`.
- The V12 MAX's switch assignment is recorded for the first time, in a `radio/v12-max/` document.
- `radio/README.md` is reframed from "the radio" to shared transmitter-side material, with a short
  index of the radios. The V12-specific material that only makes sense on EdgeTX (GPSQR widget,
  logical-switch alarms, ELRS Lua menu paths) is marked as V12-only rather than moved, so existing
  links keep working.
- The GPSQR widget is **not** ported. The R1 has its own *Find Drone* QR function, which the user
  has chosen to rely on on the R1.
- No aircraft `.txt` config changes for the R1. The radio is being fitted to the aircraft, not the
  reverse.
- **One aircraft fix, found while checking the R1 and folded in at the user's request:** the
  Meteor75 sent no telemetry at all. `feature TELEMETRY` was never enabled on it — absent from all
  three captures, the 2026-01-30 factory original included — and its board target sets no default
  features, so no `RxBt`, `Curr`, `Capa` or `FM` reached any radio, the V12 included. Enabled on the
  aircraft and saved 2026-09-30; `RxBt` then appeared on the R1. `M75_PRO_ELRS_V1.txt` gains
  `feature TELEMETRY` and a fresh capture is committed as evidence. The SBUS variant does not change.

## Capabilities

### New Capabilities

- `radio/channel-mapping`: what any radio in the fleet must guarantee about the channels it
  sends — that every AUX function an aircraft's committed config uses arrives, on a control of the
  right type, and that this is proven on the Receiver tab rather than assumed. Covers switch type
  per function, keeping GPS Rescue off controls that can be pressed by accident, carrying CH10
  through the link settings, and not treating a radio-side throttle cut as a disarm.

### Modified Capabilities

- `meteor75-pro/flight-config`: adds a requirement that the ELRS config enables Betaflight
  telemetry, with a falsifying observation on the radio.

`radio/gpsqr-widget` is unchanged: it still describes the widget on the V12 MAX, and its
"Radio-side documentation SHALL NOT restate per-aircraft flight controller settings" requirement
applies to the new R1 document as written.

## Impact

- New: `radio/oxbot-r1/README.md`, `radio/v12-max/README.md`.
- Edited: `radio/README.md` (framing and index only), `HANDOFF.md` (radio row in the status table).
- Linked, not edited: `pavo20-pro-ii/BINDING_GUIDE.md` and `pavo20-pro-ii/FAILSAFE.md`,
  `meteor75-pro/README.md` — the channel tables already live there.
- Aircraft: `meteor75-pro/M75_PRO_ELRS_V1.txt` (one `feature` line), a new capture in
  `meteor75-pro/dumps/` with the 2026-09-29 capture retitled, the Meteor75 section of `HANDOFF.md`.
  No other aircraft configuration, and no firmware or Lua changes.
- Nothing is proven until the bench check passes on both aircraft and the R1 is flown. GPS Rescue
  on the Pavo20 remains untested in the air on any radio.
