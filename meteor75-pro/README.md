# Meteor75 Pro

BetaFPV Meteor75 Pro, 1S 75 mm whoop. Flown mostly outdoors in a park — cruising around and over a
big tree, with the occasional power loop. Acro for flying; Angle for take-off and landing.

- **Board target:** `BETAFPVG473` (STM32G47X), manufacturer `BEFH`
- **Firmware:** Betaflight 4.5.1 (`Dec  6 2024`, `77d01ba3b`), MSP API 1.46
- **Video:** DJI air unit on **UART4**, MSP + VTX_MSP (`serial 3 131073`)
- **Receiver:** ELRS (CRSF) on **UART3**, RX pin PB11 — flown with the HelloRadio V12 MAX.
  Alternative: SBUS from the DJI air unit on **UART1**, RX pin PA10, for the DJI RC.
  Physical pad labels for these pins have not been recorded.
- **Motors:** DSHOT300, bidirectional DShot, 12 poles
- **Packs:** Lava 2 LiHV 1S, 580 and 680 mAh, 4.35 V full charge
- **PID tune:** BetaFPV's factory `GF 40mm`, unmodified

The authoritative record of the aircraft is the newest ` - current` capture in `dumps/`. Where a
document disagrees with that capture, the capture is right.

## Files

- `M75_PRO_ELRS_V1.txt` — flight config, ELRS / HelloRadio V12 MAX. **This is the one in use.**
- `M75_PRO_SBUS_V1.txt` — flight config, SBUS / DJI RC via the air unit. Identical except for the
  `serial` block and `serialrx_provider`. **Untested** — see its header before pasting.
- `BINDING_GUIDE.md` — binding a radio to the onboard ELRS receiver
- `dumps/` — raw `diff all` captures, named with the date taken and a suffix saying what the
  state was: ` - original` (factory), ` - as found` (2026-09-29, before the V1 configs),
  ` - current` (what is flying now). Exactly one carries
  ` - current`; retitle the previous one when a new capture replaces it.

`M75_hello_radio_v12.txt`, `M75_PRO_CLAUDE_CODE_V1.txt` and `M75_PRO_RADIOMASTER_POCKET_V1.txt` were
retired on 2026-09-29 and are in git history. Do not restore them: the Pocket file assigns
`131072` (`FUNCTION_VTX_MSP`) to UART2 in place of a receiver, and none of the three matched the
aircraft.

## Switches

| Channel | Low | Mid | High |
|---|---|---|---|
| CH5 | — | — | ARM |
| CH6 | ANGLE | ACRO | TURTLE |
| CH7 | — | — | PREARM — the quad will not arm without it |
| CH8 | — | — | BEEPER |
| CH9 | Rate: **Cine** | Rate: **Park** | Rate: **Base** |

CH9 switches rate profile in flight. The quad beeps 1, 2 or 3 times on change and the OSD shows
the profile name.

## Rate profiles

Actual rates. All three have the same throttle curve (`thr_mid 45`, `thr_expo 65`) and full
throttle, so CH9 changes stick authority only.

| Profile | Roll/pitch centre / max / expo | Yaw centre / max / expo | Use |
|---|---|---|---|
| 0 **Cine** | 40 / 450 °/s / 0.45 | 40 / 400 °/s / 0.40 | Cruising around the tree. Same numbers as the Pavo20's Cine. |
| 1 **Park** | 50 / 600 °/s / 0.50 | 50 / 540 °/s / 0.45 | A midpoint for comparison — not a published value. |
| 2 **Base** | 50 / 720 °/s / 0.45 | 50 / 540 °/s / 0.45 | BetaFPV stock. Power loops and rolls. |

Roll/pitch rate in °/s at each stick position:

```
stick %        10   20   30   40   50   60   70   80   90  100
Cine            6   17   32   53   79  114  160  225  317  450
Park            8   21   40   65   98  142  202  288  414  600
Base            9   25   48   80  122  177  251  355  504  720
```

**Keep Center Sensitivity well below Max Rate.** In the Configurator's Rates tab, Center
Sensitivity is `rc_rate`. If it reaches Max Rate, Betaflight drops expo entirely and the curve
becomes a straight line (`applyActualRates`, `fc/rc.c`). On 2026-09-29 rate profile 0 had Center
Sensitivity 1150 against Max Rate 720 — 115 °/s at 10 % stick — and the quad was reported as "way
too sharp, no range for smooth turns". To soften a profile, lower Max Rate or raise expo; leave
the centre at 40–50.

## Battery settings

`vbat_max_cell_voltage = 450` is required for LiHV. At 4.5.1 a 1S reading above this value counts
as **no battery** (no cell count, no warnings, no PID-profile auto-select), and a reading exactly
equal to it counts as 2S. The firmware default of 430 and the previously committed 435 both fail
on a freshly charged 4.35 V pack. Re-check it before flying any pack with a higher full-charge
voltage.

`vbat_min_cell_voltage = 320` and `vbat_warning_cell_voltage = 333` are BetaFPV's factory values.
The radio-side voltage alarm is separate — see `radio/README.md`.

## Applying a config

1. Connect over USB, open the CLI. Paste the config **in chunks** — the Configurator CLI drops lines
   from large pastes. Watch for error lines.
2. Let `save` reboot the board.
3. **Setup → Calibrate Accelerometer, quad level.** The committed configs carry no
   `acc_calibration` on purpose, so a paste never overwrites a good calibration with a stale one.
   Do not fly without this step.
4. Take a fresh `diff all` and compare it with the file. Expected differences: `acc_calibration`,
   `mcu_id`, `signature`, comments, and the pinned defaults in the ELRS file (`serial 0 0`,
   `serial 2 64`, `serialrx_provider = CRSF`) and the empty `profile 1`–`3` blocks, which `diff all`
   does not print. Anything else means a line was dropped or rejected.
5. Save the capture to `dumps/` as ` - current`, with `mcu_id` redacted, and commit it.

After changing anything in the Configurator, repeat steps 4–5. The GF 40mm tune was lost and a
1150 °/s rate profile went unnoticed for months because the repo was never compared against the
aircraft.

## Accelerometer — check after every crash

This board's accelerometer X axis has a zero point that shifts on impact (probable hardware
fault, recorded in `HANDOFF.md` under *Meteor75 — configs rewritten, not yet flown*). After a
crash, Angle mode may hold the wrong "level" and the quad will lean or drift.

After any crash, before the next flight:

1. Put the quad on a flat surface, connect, open the **Setup** tab.
2. If the 3D model is not level, run `get acc_calibration` in the CLI, then **Calibrate
   Accelerometer**, then `get acc_calibration` again. Note both values in `HANDOFF.md`.
3. If X in `acc_calibration` is beyond about ±25000, recalibrate once more: the sensor clips at
   ±16 g (±32768 counts), and an offset that close leaves no room.

Acro does not use the accelerometer and is unaffected. A healthy board levels to X, Y and Z all
within a few hundred counts of 0 — the factory board read `24,15,46`.

## PID profile

Profile 0 is BetaFPV's `GF 40mm` tune, verbatim from the factory dump, with
`auto_profile_cell_count = 1` so a 1S pack selects it on connect. Profiles 1–3 are left at
firmware defaults, which carry the STAY value — and at 4.5.1 a quad left on a STAY profile is never
moved off it by a battery connect (`changePidProfileFromCellCount`, `config/config.c`). The config
therefore ends on `profile 0`. If `status` or the OSD ever shows a profile other than `GF 40mm`,
select profile 0 and save.

## CLI reference

Mode IDs, serial function bits and OSD position encoding are in `docs/betaflight-reference.md`.
The ones this aircraft uses:

| ID | Mode |
|---|---|
| 0 | ARM |
| 1 | ANGLE |
| 13 | BEEPER |
| 35 | TURTLE (flip over after crash) |
| 36 | PREARM |

`aux <index> <mode_id> <channel> <low> <high> 0 0` — channel is 0-indexed from AUX1:
`0` = CH5 … `4` = CH9.
