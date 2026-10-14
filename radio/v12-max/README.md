# HelloRadio V12 MAX

EdgeTX radio with a built-in ELRS module. The original radio for this fleet, and the one the GPSQR
widget and the logical-switch alarms were built on. Those stay documented in `../README.md`, which
is where the links from the rest of the repo already point.

## Switch assignment

Recorded 2026-09-30 from the user's description. It had not been written down anywhere before.

| CH | AUX | Function | V12 control | Type |
|---|---|---|---|---|
| CH5 | AUX1 | ARM | SA | 2-position |
| CH6 | AUX2 | ANGLE / acro / TURTLE | SB | 3-position |
| CH7 | AUX3 | PREARM | SD | momentary |
| CH8 | AUX4 | BEEPER | front button 3 | button |
| CH9 | AUX5 | rate profile (+ LEDLOW on the Pavo20) | SC | 3-position |
| CH10 | AUX6 | GPS RESCUE, Pavo20 only | front button 6 | button |

The front buttons were first given from memory as "4" and "6". Checked on the radio on 2026-10-01:
**BEEPER is button 3**, GPS Rescue is button 6.

What each position does is set on the aircraft, not here — the ranges live in the aircraft's
channel table and differ between aircraft:

- **Pavo20 Pro II** — `../../pavo20-pro-ii/BINDING_GUIDE.md`, *Switch layout used by these configs*;
  the CH10 rescue line is in `../../pavo20-pro-ii/FAILSAFE.md`
- **Meteor75 Pro** — `../../meteor75-pro/README.md`, *Switches*
- **Meteor75 Pro II** — [aircraft switch table](../../meteor75-pro-ii/README.md#switches).
  Its current setup targets the Oxbot R1. Pro II operation on the V12 MAX remains unverified.

## ELRS link

Set to **`333Hz Full`** with Switch Mode **`12ch Mixed`**, since 2026-09-03. `12ch Mixed` is what
lets CH10 reach the Pavo20 at a Full-Resolution rate; `8ch` silently drops it. Why, and what that
costs on CH5, is in `../../pavo20-pro-ii/BINDING_GUIDE.md` and in `../README.md` under *What each
Full-Res switch mode actually transmits*.

Pairing is by the shared binding phrase, entered in the ELRS Lua script. See `../README.md`,
*Pairing*.

## V12-only features

These need EdgeTX and are not available on the other radios:

- **GPSQR widget** — `../README.md`, *GPSQR — the "find my drone" widget*
- **Battery, capacity and link-quality alarms** (logical switches `L01`–`L03`) — `../README.md`,
  *The alarm itself*, *mAh alarm* and *Transmitter power and link warnings*
- **SD card flight logs** on the arm switch — `../README.md`, *Field workflow*
