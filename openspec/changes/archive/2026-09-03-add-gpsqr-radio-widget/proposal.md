## Why

The fleet has no recovery tool for a quad that goes down out of sight. `pavo20-pro-ii/FAILSAFE.md`
says plainly that a rescue "can still fail" and that the Pavo20's GPS Rescue is configured but
never tested — so the last-known-position problem is live, not hypothetical. GPSQR is a working
EdgeTX widget already on the radio that renders the last GPS fix as a scannable Google Maps QR and
persists it to the SD card across a radio power cycle. It exists only in a ZIP in `Downloads/` and
is not backed up, versioned or reviewed.

Reviewing it against the EdgeTX Lua API surfaced a defect that matters in the field: the widget
never sets the QR code's colours, so both foreground and background fall back to theme colours and
the code can be rendered dark-on-dark — unscannable exactly when it is needed. Its bundled README
also carries Betaflight advice that contradicts findings this repo paid for in bench time.

## What Changes

- Add a new top-level `radio/` folder for transmitter-side configuration, mirroring the SD-card
  layout so `radio/WIDGETS/GPSQR/main.lua` copies straight to the card root. The V12 MAX is shared
  across all three aircraft, so this is fleet-wide content and does not belong under one airframe.
- Commit the GPSQR widget with the review fixes applied:
  - Pin the QR code to explicit black-on-white (`color = BLACK`, `bgColor = WHITE`). Unset, EdgeTX
    defaults them to `COLOR_THEME_SECONDARY1` / `COLOR_THEME_SECONDARY3`.
  - Stop the unbounded SD-write retry when `/LOGS/` is missing or the card is unwritable.
  - Guard the computed QR dimension against non-positive values in small widget zones.
  - Show fix age on square zones, where the current layout suppresses it entirely and a stale
    saved fix is indistinguishable from a live one.
- Add `radio/CODE_REVIEW.md` recording every finding, including those deliberately not fixed and
  the one that cannot be settled without the radio in hand (whether widget LVGL coordinates are
  zone-relative or screen-absolute).
- Split the bundled README. `radio/README.md` keeps the radio-side material — widget install and
  use, ELRS telemetry discovery, battery and link-quality alarms, TX power. The aircraft-side
  sections become cross-references to `pavo20-pro-ii/FAILSAFE.md` and `pavo20-pro-ii/GPS_SETUP.md`
  rather than duplicated advice that is stale for the firmware in use.
- **Remove the shipped README's §3 GPS advice** ("protocol UBLOX, auto-baud"). Applied to the
  Pavo20's BZ-181 it is the documented wrong answer: that module never answers a UBX `MON-VER`, so
  the UBLOX driver cannot leave `DETECT_BAUD`. Record why it was removed rather than deleting it
  silently.
- Update `README.md` (fleet layout table and conventions) and `HANDOFF.md` (recovery workflow, and
  the widget's dependency on the untested first outdoor fix).

## Capabilities

`openspec/specs/` is currently empty — this change seeds it. The path establishes a `radio/` vs
per-aircraft split matching the repo's folder layout.

### New Capabilities

- `radio/gpsqr-widget`: What the on-radio recovery widget must guarantee — that a displayed QR is
  scannable regardless of radio theme, that a displayed position is never silently stale, that the
  last fix survives a radio power cycle, and that the widget cannot degrade flight-critical radio
  behaviour while it runs in the background.

### Modified Capabilities

None. No existing specs.

## Impact

- **New:** `radio/README.md`, `radio/CODE_REVIEW.md`, `radio/WIDGETS/GPSQR/main.lua`.
- **Modified:** `README.md`, `HANDOFF.md`, `CLAUDE.md` (layout description only).
- **Aircraft configs: unchanged.** Nothing here touches a `.txt` config or alters how any quad
  flies. The one aircraft-side setting the widget documentation recommends —
  `set report_cell_voltage = ON`, so per-cell alarm thresholds work across cell counts — is
  written up as a step for the user to apply and verify, not applied to a committed config.
- **Verification is on real hardware.** The corrected `main.lua` must be copied to the V12 MAX SD
  card and confirmed to render a scannable code on both a light and a dark theme before this
  change is archived. Nothing in this repo can test it.
