## Why

The Meteor75 Pro flew badly on 2026-09-29: too sharp in Acro, with no stick range for smooth turns
around a tree. A `diff all` taken that evening showed the aircraft no longer resembles any file in
this repo. Rate profile 0 had a centre sensitivity of 1150°/s — set by hand in the Configurator,
which disables expo entirely — and PID profile 0 had been reset to Betaflight defaults, losing
BetaFPV's GF 40mm whoop tune. `HANDOFF.md` records the Meteor75 as "stable, no outstanding work";
nothing in the repo could have caught either change, because nothing requires the committed config
to be compared against the aircraft.

Reading the source while diagnosing it also showed that two committed values are actively wrong
for the packs in use, and that one committed config cannot work at all.

## What Changes

- **Replace the rate profiles** with a Cine / Park / Base family on the existing CH9 3-position
  switch: one expo shape, rising maximum rate, full throttle on all three. Cine uses the Pavo20's
  Cine numbers so centre-stick feel carries between aircraft. This replaces the live
  `Base 100` / `Base 80` / `Base 60` throttle-scale set, two of which carry accidental
  `rc_rate` values (115 and 16).
- **Restore the GF 40mm PID tune** from the 2026-01-30 factory dump, with `dyn_idle_min_rpm` at the
  factory `30` rather than the unexplained `75` in the repo's V1 files.
- **Keep `vbat_max_cell_voltage = 450`** as found on the aircraft. The repo's `435` makes a freshly
  charged LiHV cell detect as 2S, which also drives the PID-profile auto-switch to the wrong
  profile.
- **Two variant configs, mirroring the Pavo20:** `M75_PRO_ELRS_V1.txt` (CRSF on UART3, as flown)
  and `M75_PRO_SBUS_V1.txt` (SBUS from the DJI air unit on UART1, as shipped).
- **Retire** `M75_hello_radio_v12.txt`, `M75_PRO_CLAUDE_CODE_V1.txt` and
  `M75_PRO_RADIOMASTER_POCKET_V1.txt`. The Pocket file assigns `131072` (`FUNCTION_VTX_MSP`) to
  UART2 while labelling it the ELRS receiver; pasted, it leaves the aircraft with no RX.
- **Commit the 2026-09-29 capture** to `meteor75-pro/dumps/` with `mcu_id` redacted.
- **Remove `acc_calibration`** from committed Meteor configs, as already done for the Pavo20.
- **Rewrite `meteor75-pro/README.md`** (currently a stale CLAUDE.md that maps mode ID 0 to ANGLE;
  0 is ARM) and correct `BINDING_GUIDE.md` (says UART2; the receiver is on UART3).
- **Update `HANDOFF.md`**: the Meteor75 is no longer "stable, no outstanding work" until flown.

**Not in scope:** firmware upgrade (stays 4.5.1), any PID value other than the factory tune,
OSD layout changes beyond taking what the aircraft has now.

## Capabilities

### New Capabilities

- `meteor75-pro/flight-config`: What a committed, re-pasteable Meteor75 config must guarantee —
  no airframe calibration, verifiable against a dated capture, rate curves whose expo can act, a
  cell-voltage ceiling that detects the packs actually flown as 1S, and an active PID profile that
  cell-count selection can reach.

### Modified Capabilities

None. `pavo20-pro-ii/flight-config` covers several of the same ideas, but promoting them to a
fleet-wide capability is a separate decision (`HANDOFF.md` under *Known gap: the FireFly25 still commits calibration*) and is not made here.

## Impact

- `meteor75-pro/M75_PRO_ELRS_V1.txt`, `meteor75-pro/M75_PRO_SBUS_V1.txt` — new
- `meteor75-pro/M75_hello_radio_v12.txt`, `M75_PRO_CLAUDE_CODE_V1.txt`,
  `M75_PRO_RADIOMASTER_POCKET_V1.txt` — removed (git history keeps them)
- `meteor75-pro/dumps/BTFL_cli_backup_M75_PRO_20260929_BETAFPVG473 - as found.txt` — new, redacted;
  ` - current.txt` is the post-paste round-trip capture
- `meteor75-pro/README.md`, `meteor75-pro/BINDING_GUIDE.md` — rewritten / corrected
- `HANDOFF.md` — Meteor75 status and outstanding flight test

Flight behaviour changes substantially: softer rates on every switch position and a different PID
tune. Nothing here is trusted until flown (see `design.md`, Open Questions).
