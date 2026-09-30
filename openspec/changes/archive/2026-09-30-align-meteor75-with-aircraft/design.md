# Design

This document is written to be self-contained: every value the two configs must carry is stated
here or in a named repo file, with its source. Implementation should not need the conversation that
produced it, nor the capture file in the pilot's Downloads folder.

## Context

See `proposal.md` for why. Firmware is Betaflight **4.5.1** (`STM32G47X (SG47) ... Dec  6 2024,
77d01ba3b`), board target `BEFH/BETAFPVG473`. Every source citation below was read at tag `4.5.1`.

### The aircraft on 2026-09-29 (`diff all`, 21:26)

Source file: `C:\Users\ezagv\Downloads\BTFL_cli_M75_PRO_20260929_212636_BETAFPVG473.txt`. It
contains the real `mcu_id` and must be redacted before it enters the repo (`HANDOFF.md` under *Decide about the MCU ID in git history*).
What matters from it:

```
serial 1 0 115200 57600 0 115200
serial 3 131073 115200 57600 0 115200
aux 0 0 0 1700 2100 0 0        # ARM      CH5 high
aux 1 1 1 900 1300 0 0         # ANGLE    CH6 low
aux 2 13 3 1700 2100 0 0       # BEEPER   CH8 high
aux 3 35 1 1700 2100 0 0       # TURTLE   CH6 high
aux 4 36 2 1700 2100 0 0       # PREARM   CH7 high
adjrange 0 0 4 900 1200 12 4 0 0
adjrange 1 0 4 1375 1675 12 4 0 0
adjrange 2 0 4 1800 2100 12 4 0 0
set acc_calibration = -17621,-71,65,1
set vbat_max_cell_voltage = 450
(no vbat_min_cell_voltage / vbat_warning_cell_voltage lines -> firmware defaults 330 / 350)
(OSD: 31 osd_*_pos lines - carry verbatim from the capture)
profile 0          <- empty: every PID setting at firmware default; GF 40mm tune lost
rateprofile 0  Base 100  thr 45/65  roll,pitch rc 115 srate 72 expo 45   yaw rc 5 srate 54 expo 45
rateprofile 1  Base 80   thr 45/50  roll,pitch rc 5   srate 72 expo 45   yaw rc 5 srate 54 expo 45  throttle SCALE 80
rateprofile 2  Base 60   thr default roll,pitch rc 16 srate 72 expo 45   yaw rc 7 srate 54 expo 45  throttle SCALE 60
```

`serial` and `get serialrx_provider` on the same evening:

```
serial 20 1 ...   (USB VCP, MSP)
serial 0 0 ...    UART1  unused
serial 1 0 ...    UART2  unused
serial 2 64 ...   UART3  RX_SERIAL
serial 3 131073   UART4  MSP + VTX_MSP (DJI air unit)
serialrx_provider = CRSF
```

`serial 2` and `serialrx_provider` are absent from the `diff all` because they equal the board
target's defaults: `SERIALRX_UART SERIAL_PORT_USART3` and `SERIALRX_PROVIDER SERIALRX_CRSF` in
`betaflight/config` `configs/BEFH/BETAFPVG473/config.h`.

Function bits (`src/main/io/serial.h:37-53`): `FUNCTION_MSP = 1`, `FUNCTION_RX_SERIAL = 64`,
`FUNCTION_VTX_MSP = 131072`.

### The factory dump (2026-01-30)

`meteor75-pro/dumps/BTFL_cli_backup_M75_PRO_20260130_212146_BETAFPVG473 - original.txt` holds
BetaFPV's shipped config: SBUS on UART1 (`serial 0 64`, `serial 2 0`, `serialrx_provider = SBUS`),
the **GF 40mm** PID profile, `vbat_max/min/warning_cell_voltage = 440/320/333`, and
`dyn_idle_min_rpm = 30`.

## Goals / Non-Goals

**Goals:**
- Two committed configs that, pasted, reproduce the aircraft as it should fly, and round-trip
  against a fresh capture (`specs/meteor75-pro/flight-config`).
- A rate family the pilot can compare in flight from one switch without landing.

**Non-Goals:**
- Tuning. The PID profile is the manufacturer's, restored verbatim.
- OSD redesign. The live layout is taken as-is.
- A fleet-wide flight-config capability. Parallel wording to the Pavo20 spec is deliberate so the
  later merge is mechanical.

## Decisions

### D1. Rate family: Cine / Park / Base on CH9, one shape, full throttle

| CH9 | profile | name | roll & pitch rc / srate / expo | yaw rc / srate / expo | thr_mid / thr_expo |
|---|---|---|---|---|---|
| low | 0 | `Cine` | 4 / 45 / 45 | 4 / 40 / 40 | 45 / 65 |
| mid | 1 | `Park` | 5 / 60 / 50 | 5 / 54 / 45 | 45 / 65 |
| high | 2 | `Base` | 5 / 72 / 45 | 5 / 54 / 45 | 45 / 65 |

No `throttle_limit_*` lines on any profile. Rate profile 3 stays at defaults. Names are ≤ 8
characters (`docs/betaflight-reference.md`).

Resulting curves, from `applyActualRates` (`src/main/fc/rc.c:209-219`), in °/s:

```
stick %               10   20   30   40   50   60   70   80   90  100
Cine  roll/pitch       6   17   32   53   79  114  160  225  317  450
Park  roll/pitch       8   21   40   65   98  142  202  288  414  600
Base  roll/pitch       9   25   48   80  122  177  251  355  504  720
Cine  yaw              6   17   32   51   76  108  151  208  287  400
Park/Base yaw          8   21   39   64   96  137  193  270  380  540
(2026-09-29 profile 0 115  230  345  460  575  690  805  920 1035 1150)
```

- **Cine** is the Pavo20's Cine profile number for number (`PAVO20PRO2_ELRS_V1.txt`, rateprofile 0),
  so centre-stick feel is the same on both aircraft. Intended for cruising around the tree.
- **Base** is BetaFPV's stock whoop curve from the factory dump. Intended for power loops and rolls.
- **Park** is a midpoint **chosen in this change, not a published value**. It exists so the pilot
  has a third point to compare. `rc_rate` is an integer in tens of °/s, so 45 °/s is not
  expressible; 50 was used.
- `thr_mid 45 / thr_expo 65` is the live rateprofile 0 throttle curve, applied to all three so that
  switching CH9 in flight changes stick authority only, never throttle feel.

The switch mapping is established by source: for `ADJUSTMENT_RATE_PROFILE` in select mode the
position is `(constrain(rcData, 900, 2099) - 900) / ((2100 - 900) / 3)` —
`src/main/fc/rc_adjustments.c:801-806` — so low, mid and high select profiles 0, 1 and 2, and
`applySelectAdjustment` (`:599-611`) beeps position + 1 on change. The three live `adjrange` lines
are kept unchanged; each gates one CH9 third, together covering the switch.

*Alternatives considered:* (a) keep the throttle-scale family (`Base 100/80/60`) with a corrected
`rc_rate` — rejected: throttle scaling suits indoor flying, and a power loop needs full throttle.
(b) Mirror the Pavo20 exactly (`Cine / Base / Scale 70`) — rejected for the same reason; alignment
is kept where it carries across aircraft, which is the Cine curve and the switch layout.

### D2. PID profile: GF 40mm, verbatim from the factory dump

Profile 0 receives the factory dump's entire `profile 0` block unchanged, from
`set profile_name = GF 40mm` through `set tpa_rate = 80` — including
`auto_profile_cell_count = 1` and `dyn_idle_min_rpm = 30`. Profiles 1–3 carry no lines. The file
ends on `profile 0`. This satisfies *The active PID profile SHALL be reachable by cell-count
selection*.

*Alternatives considered:* `dyn_idle_min_rpm = 75`, as in `M75_PRO_CLAUDE_CODE_V1.txt` and
`M75_hello_radio_v12.txt`. Rejected: nothing records why it was raised, and `CLAUDE.md` says
never invent tune numbers. Units are hundreds of RPM (`dynIdleMinRps = dyn_idle_min_rpm * 100 /
60`, `src/main/flight/mixer_init.c:332`), so 30 means 3000 RPM. If throttle chops in power loops
feel soft after flying, raising it is a later, separate, versioned change. `crash_recovery = ON`
from the v12 file is not carried: it sat on a default-PID profile and has no recorded reason.

### D3. Battery: 450 / 320 / 333

`vbat_max_cell_voltage = 450` (live value) for the reasons in the spec requirement *The
cell-voltage ceiling SHALL detect a freshly charged pack as present, as 1S*.

`vbat_min_cell_voltage = 320` and `vbat_warning_cell_voltage = 333` are restored from the factory
dump. They were dropped by every later file and the aircraft now runs the firmware defaults
330 / 350 (`src/main/sensors/battery.h:35`, `battery.c:110`), which on a 1S whoop that sags hard
under punch would put the OSD warning up early in most flights. This is the manufacturer's value,
not a new one. The radio-side voltage alarm in `radio/README.md` is separate and unchanged.

### D4. Two variants, receiver and port only

Both files are identical except for the receiver block:

| | `M75_PRO_ELRS_V1.txt` | `M75_PRO_SBUS_V1.txt` |
|---|---|---|
| UART1 (`serial 0`) | `0` | `64` — RX_SERIAL |
| UART3 (`serial 2`) | `64` — RX_SERIAL | `0` |
| UART4 (`serial 3`) | `131073` | `131073` |
| `serialrx_provider` | `CRSF` | `SBUS` |
| MCU pin, receiver → FC | UART3 RX = **PB11** | UART1 RX = **PA10** |
| Source | 2026-09-29 capture | 2026-01-30 factory dump |

MCU pins are from `configs/BEFH/BETAFPVG473/config.h` (`UART1_RX_PIN PA10`, `UART3_RX_PIN PB11`).
The physical pad labels on this board have not been read off the hardware; see Open Questions.

The ELRS file writes `serial 2 64` and `set serialrx_provider = CRSF` explicitly even though both
equal the board default, with a comment saying so and naming 4.5.1 / the `BETAFPVG473` target:
they decide whether the aircraft has a receiver at all, and the SBUS file changes both. This is the
pinned-default exception, as the Pavo20 does for `gps_provider`.

`sbus_baud_fast` is not set: the factory dump does not set it, and the `ON` in
`M75_PRO_CLAUDE_CODE_V1.txt` has no recorded reason.

Everything else — AUX, `adjrange`, OSD, filters, motor, current sensor — is the 2026-09-29
capture, minus `acc_calibration`, with D1–D3 applied. Header comments follow
`PAVO20PRO2_ELRS_V1.txt`: base, what is added, `AFTER PASTING: calibrate accelerometer`, the
8-character name limit. `batch start` / `defaults nosave` / `save` are preserved.

### D5. Retire the three old configs

`M75_hello_radio_v12.txt`, `M75_PRO_CLAUDE_CODE_V1.txt` and `M75_PRO_RADIOMASTER_POCKET_V1.txt`
are deleted; git history keeps them. The Pocket file is not merely stale but non-functional:
`serial 1 131072` is `FUNCTION_VTX_MSP`, not `FUNCTION_RX_SERIAL`, so pasting it leaves no
receiver. None is worth keeping as a variant, and leaving them beside the new files invites pasting
the wrong one.

## Risks / Trade-offs

- **[Cine may feel too slow over the tree, Base too fast]** → the switch exists to compare them in
  one flight; changing a curve is a new versioned file, not an edit to V1.
- **[The factory tune plus softer rates may still feel sharp, if the cause was partly the
  airframe]** → the 2026-09-29 profile 0 alone explains the symptom (spec, *centre sensitivity*),
  but only a flight confirms it. If it persists on Cine, capture a blackbox log before touching
  PIDs.
- **[Chunked paste drops a line silently]** → the round-trip requirement: `diff all` after paste
  and compare. Paste in chunks per `CLAUDE.md`.
- **[SBUS variant mapped to the ELRS AUX layout]** → the DJI RC's switch-to-channel mapping has not
  been checked against CH5–CH9. The SBUS file must not be flown until the Receiver tab shows each
  AUX switch moving the channel the file expects.

## Migration Plan

Paste `M75_PRO_ELRS_V1.txt` in chunks → `save` → Calibrate Accelerometer, quad level → `diff all`
and compare → hover test in Angle → Acro on each CH9 position.

Rollback: paste the 2026-09-29 capture (restore the real `mcu_id` line from the original file, or
omit it) — it reproduces the aircraft as found.

## Open Questions

Nothing in this change has flown. Each item below is untested on hardware, with what settles it and
who does it. All tests are performed by the pilot.

1. **Do the rates suit the flying?** Settled by one flight, in Acro, over the park tree, trying
   CH9 low, mid and high. Pass: small stick movements at centre give slow, controllable rotation on
   all three; Base completes a power loop without running out of rate. A new curve goes in a new
   versioned file.
2. **Does the restored GF 40mm tune fly correctly on this airframe today?** It is BetaFPV's
   published tune and flew from the factory, but this airframe has been flown on default PIDs since
   an unknown date and the props or motors may have changed. Settled by a hover in Angle, then
   Acro: no oscillation, no hot motors after a pack (touch-check on landing).
3. **Dynamic idle at 30.** Settled by throttle chops and power loops: pass if the quad keeps
   authority at zero throttle without bobbing. If not, raise in a separate change.
4. **Battery detection with 450.** Settled on the bench: plug in a freshly charged Lava LiHV pack,
   disarmed; OSD shows a 1S voltage immediately and `status` reports the GF 40mm profile active.
5. **The SBUS variant is entirely untested.** It reproduces the factory receiver setup but has
   never been pasted by the pilot. Settled when the DJI RC is next used: bind, paste the SBUS
   file, Receiver tab shows sticks and CH5–CH9 moving as the AUX table expects, arm on the bench
   with props off, then fly.
6. **Physical pad labels for UART1 RX (PA10) and UART3 RX (PB11).** Not read off the board. Settled
   by the BetaFPV wiring diagram or by inspection, and recorded in `meteor75-pro/README.md`.
7. **Is the accelerometer X axis damaged?** Found during the bench round-trip, outside this
   change's original scope. X offsets of −12851, −17621, −30382 and −21126 counts (−6 to −15 g at
   2048 counts/g) across levellings, against 24 at the factory, with Y and Z healthy; the pilot
   reports Angle mode misbehaving after crashes. Nothing in this change's configs depends on it —
   they carry no `acc_calibration` — but the spec scenario *Pasting onto a levelled aircraft*
   assumes a sensor worth levelling. Settled by recording `get acc_calibration` before and after
   recalibrating following the next crash; a jump of thousands of counts in X confirms it. Full
   record in `HANDOFF.md` under *Meteor75 — configs rewritten, flying, checks outstanding*. Fix is hardware.
8. **How the tune was lost.** The pilot believes it happened while changing things in the
   Configurator. Not recoverable and not needed for the fix; the capture requirement is what
   prevents a repeat.
