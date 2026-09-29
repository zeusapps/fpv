## Why

The Pavo20 Pro II has GPS Rescue configured on a switch but **cannot be trusted with it as a
failsafe**, and the first field attempt proved it: triggered on 2026-09-03 at 20–30 m with ~26
satellites, the aircraft came down and the motors stopped. Until that is understood and corrected,
arming `failsafe_procedure = GPS-RESCUE` would mean the next lost link runs a rescue that has
already put the quad on the ground once — a flyaway under power rather than a broken quad.

Getting to that test exposed three further problems worth fixing permanently: the rescue switch
was never reaching the aircraft at all, the config bundled a dangerous line with harmless ones,
and the one line that arms the failsafe was written in a form the CLI silently rejects.

This change leaves the aircraft **configured and instrumented, with the failsafe still on `DROP`**.
The flight test that would justify arming it is explicitly out of scope and stays with the pilot.

## What Changes

- **Correct the hover throttle reference.** `ap_hover_throttle` is at the firmware default of
  `1275` (27.5%) while this airframe hovers near 34% (`thr_hover = 34`). At rescue start the
  altitude integrator is reset and the target altitude equals the current altitude, so commanded
  throttle is essentially `ap_hover_throttle` — below hover, so the quad sinks instead of climbing.
- **Instrument the aircraft for the pilot's own test.** `debug_mode = RTH` so the next attempt
  records rescue phase, failure code and max altitude rather than leaving the outcome to memory.
- **Keep the two-block config split** — parameters separate from the single line that arms the
  failsafe — and keep block 2 unpasted behind a written gate.
- **Fix the silently-rejected value.** `set failsafe_procedure = GPS_RESCUE` was wrong; the CLI
  lookup table is `{"AUTO-LAND", "DROP", "GPS-RESCUE"}`.
- **Record the rescue trigger geometry** so a future test is not read as a fault: below 5 m from
  home and 4 m altitude the rescue disarms deliberately; below `gps_rescue_min_start_dist` it flies
  *away* before returning.
- **Record the ELRS constraint** that made the switch dead: Full-Resolution `8ch` transmits nothing
  above CH9.
- **Close the widget's no-fix defect** now that the satellite sensor is confirmed to be `Sats`.

**Not in scope:** flying the rescue. No requirement here asserts that GPS Rescue works on this
aircraft, and none may until the pilot has flown it.

## Capabilities

### New Capabilities

- `pavo20-pro-ii/failsafe`: What the aircraft's failsafe response must be, what evidence is
  required before GPS Rescue may become that response, how the configuration is split so the
  dangerous half cannot be applied early, and the thrust and geometry preconditions a rescue
  depends on for this airframe.
- `radio/elrs-link`: Which RC channels the link actually carries. Packet rate and switch mode
  jointly decide the highest usable channel, and a channel above that ceiling fails silently —
  it neither errors nor appears wrong, it simply never moves.

### Modified Capabilities

- `radio/gpsqr-widget`: *An absent or invalid fix SHALL NOT be presented as a position* currently
  ends by requiring that the satellite sensor's name "MUST be confirmed on the radio rather than
  assumed". It is now confirmed as `Sats`. The requirement gains the sensor name, a minimum count,
  and the behaviour when the sensor is absent — which must not be conflated with a genuine zero.
- `pavo20-pro-ii/flight-config`: gains a requirement that values drawn from a firmware lookup table
  are read back with `get` after being set. A mistyped lookup value is rejected without stopping
  anything else, so in a file with no `batch start` the error scrolls past, `save` writes nothing,
  and the setting silently keeps its old value.

## Impact

- `pavo20-pro-ii/PAVO20PRO2_GPS_RESCUE_TUNING.txt` — hover throttle and debug mode
- `pavo20-pro-ii/PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt` — the gated one-line block
- `pavo20-pro-ii/FAILSAFE.md` — trigger geometry, the corrected sanity-check guidance, test procedure
- `pavo20-pro-ii/BINDING_GUIDE.md`, `radio/README.md` — ELRS switch mode and channel ceilings
- `radio/WIDGETS/GPSQR/main.lua`, `radio/CODE_REVIEW.md` — satellite gating
- `HANDOFF.md` — current state and what the field attempt did and did not prove

No aircraft behaviour changes on lost link: `failsafe_procedure` stays at the `DROP_IT` default
throughout this change.
