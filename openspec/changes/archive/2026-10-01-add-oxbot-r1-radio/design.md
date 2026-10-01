# Design

## Context

See `proposal.md` for why. The constraints that shape the approach:

- **The Oxbot R1 runs OXBOT OS, not EdgeTX.** Channel assignment is per model, under System
  Settings → Channel Settings → *Mapped Switch*, with *Channel Reverse*, *Output Range* and
  *Center Point* per channel. Its ELRS menu exposes *Packet Rate*, *Telem Ratio*, *Model Match* and
  *Bluetooth* and no *Switch Mode*. Source: the Oxbot R1 Quick Start Guide
  (`store-fnms1h2bjh.mybigcommerce.com/product_images/oxbot_r1_rc/manual/Oxbot%20R1_QSG_en.html`,
  read 2026-09-30). It is 10 channels.
- **R1 controls, reported by the user 2026-09-30:** SA 2-pos, SB 3-pos, SC 3-pos, SD 2-pos toggle,
  SE a 2-pos (latching) rear paddle, SF a momentary rear paddle. SA–SD are top toggles; SE and SF
  sit on the back of the grips.
- **V12 MAX controls, reported by the user 2026-09-30 and not previously recorded anywhere:** ARM
  SA (2-pos), modes SB (3-pos), PREARM SD (momentary), BEEPER front button 3, rates SC (3-pos),
  GPS Rescue front button 6. The beeper button was first given from memory as 4 and corrected to 3
  on the radio, 2026-10-01 (task 1.1).
- **What the aircraft read.** CH5–CH9 are identical on both quads (`PAVO20PRO2_ELRS_V1.txt`,
  `M75_PRO_ELRS_V1.txt`). CH10 is GPS Rescue on the Pavo20 only, and its `aux 6 46 5 1700 2100 0 0`
  line is recorded in `pavo20-pro-ii/FAILSAFE.md`, not in the committed ELRS config.
- **Already verified, 2026-09-30:** the R1 links to both aircraft with the binding phrase entered
  on the radio; no receiver change was needed. Before any remapping, flipping SD made the quad beep
  — consistent with SD driving CH8 (BEEPER) in the R1's default mapping. Arming was attempted and
  did not happen. The last attempt was on the Pavo20, indoors, where the GPS arming block described
  under *Risks* explains the refusal on its own, whatever PREARM was doing. Whether the Meteor75,
  which has no such block, also refused was not recorded; if it did, the cause is radio-side —
  most likely PREARM on the wrong control in the default mapping — and task 3.1 addresses it.

## Goals / Non-Goals

**Goals:**

- The R1 flies both aircraft with ARM, modes and rates on the same switch letters as the V12.
- Every channel is proven on the Betaflight Receiver and Modes tabs, over USB, without goggles.
- The V12's assignment is written down, so "like the V12" has a reference.

**Non-Goals:**

- Any change to either aircraft for the R1's sake. The radio is fitted to the aircraft. The one
  aircraft change in this change, D9, fixes a gap on the Meteor75 that affected every radio.
- Porting the GPSQR widget. The R1's *Find Drone* is the user's chosen replacement on that radio.
- Documenting the Radiomaster Pocket or the DJI RC3. The layout leaves room for them; they are not
  written up here. (The DJI RC3 reaches the aircraft over SBUS through the air unit, so it is a
  different path — the `*_SBUS_V1.txt` configs — not just another ELRS radio.)
- Choosing between the V12 and the R1. The trial is what this change enables.
- Moving the GPSQR widget out of `radio/WIDGETS/`. It mirrors the SD card layout and is referenced
  from the `radio/gpsqr-widget` spec.

## Decisions

### D1. Fit the radio to the aircraft, not the reverse

The `aux` lines stay as they are; the R1 is mapped to produce them. The alternative — rewriting the
`aux` lines to match the R1's default mapping — would change two configs that were verified against
dated captures (`meteor75-pro/flight-config`, "verifiable against a dated capture"), and would
break the V12, which is still in use while the trial runs.

### D2. GPS Rescue on SD, not on SE

Copying the V12 by control type would put rescue on a rear paddle (SE is the R1's only latching
button). Rejected: the paddles sit under the fingers for the whole flight, and an accidental rescue
hands control to a feature whose one field trigger disarmed and dropped the quad. SD is a top
toggle and needs a deliberate reach, which is what the V12's front button gave. The beeper takes
SE, where a mis-press costs nothing. Chosen by the user, 2026-09-30 ("B"). Requirement:
`radio/channel-mapping`, "GPS Rescue SHALL be assigned to a control that needs a deliberate reach".

A side effect that is in the safe direction: an SD left up at power-on blocks arming. At Betaflight
`2025.12.2`, `IS_RC_MODE_ACTIVE(BOXGPSRESCUE)` sets `ARMING_DISABLED_RESC`
(`src/main/fc/core.c:408-409`). A forgotten rescue switch shows up as a quad that will not arm,
not as a rescue on takeoff.

### D3. PREARM on SF, the momentary paddle

The V12 has PREARM on a momentary. The R1's only momentary is SF. The alternative, SD as a toggle,
would be left up, which defeats a two-step arm. A mis-press of SF in flight does nothing:
PREARM is only read at the moment of arming (`core.c:391-397`).

### D4. A standard packet rate on the R1

The R1 cannot set Switch Mode, so it cannot guarantee CH10 on a "Full" rate. On the standard rates
Hybrid and Wide both carry to CH12 (`radio/README.md`, read off ExpressLRS 3.5.6), so the switch
mode stops mattering. 250Hz is the rate `pavo20-pro-ii/BINDING_GUIDE.md` recommends for these
aircraft; 500Hz is also acceptable there. The receiver follows the transmitter's rate, so the V12
can stay on `333Hz Full` / `12ch Mixed` with no conflict.

### D5. One R1 model for both aircraft

CH5–CH9 are identical on both aircraft and the Meteor75 ignores CH10, so one R1 model flies both —
the same as the V12, which uses a single model. Chosen by the user, 2026-09-30, over an earlier
proposal of one model per aircraft. The reasons that proposal gave did not hold up:

- **Per-aircraft alarm thresholds.** Only relevant if the R1 has alarms, which is unknown, and
  per-cell reporting (`report_cell_voltage`, `radio/README.md`) already lets one threshold serve
  both aircraft.
- **Keeping each aircraft's last position apart in *Find Drone*.** The Meteor75 has no GPS, so it
  cannot overwrite the Pavo20's last position — the shared-save-file defect of the GPSQR widget has
  no counterpart here.

One model means the mapping is set once, cannot drift between copies, and cannot be flown with the
wrong model selected. Split it if a genuine per-aircraft difference appears.

*Model Match* stays off — nothing in this fleet uses it, and turning it on is a new way to fail to
connect.

### D6. Three documents under `radio/`

```
radio/README.md          shared: ELRS link, battery thresholds, field workflow, radio index
radio/v12-max/README.md  V12 switch assignment; points at the widget and LS/SF alarms
radio/oxbot-r1/README.md R1 switch assignment, settings, features left off, bench check
radio/WIDGETS/...        unchanged (SD-card mirror, V12 only)
```

`radio/README.md` keeps its V12-only sections in place, marked as V12/EdgeTX, rather than moving
them. Existing links into it from `HANDOFF.md`, the aircraft folders and the specs keep resolving.
The alternative, moving all V12 content into `radio/v12-max/`, is cleaner but churns links for no
flight-relevant gain; it can happen when a third radio is written up.

### D7. Throttle Lock off

Recorded as a setting, not a preference, because the name suggests something it does not do.
Requirement: `radio/channel-mapping`, "A radio-side throttle cut SHALL NOT stand in for disarm".

### D8. Pair by binding phrase only

Every radio in the fleet pairs with every receiver through the shared ELRS binding phrase, entered
on the radio. Receiver bind mode (three power cycles, then *Bind* on the radio) is not used. Chosen
by the user, 2026-09-30: the phrase is the versatile option, since any radio holding it links to
any receiver with no per-radio pairing step, and a new radio — the Pocket, say — joins by entering
it. Verified on the R1 with both aircraft the same day.

No claim is made here about what bind mode would do to the receivers' stored pairing; it was not
checked against the ExpressLRS source and does not need to be, since it is not used.

### D9. Enable telemetry on the Meteor75, in this change

The R1 showed no `RxBt` for the Meteor75. The cause was on the aircraft: `feature TELEMETRY` was
never set, and at Betaflight 4.5.1 nothing sets it by default on this board. Requirement and source
citations: `meteor75-pro/flight-config`, "The ELRS config SHALL enable Betaflight telemetry".

It is folded into this change at the user's request, 2026-09-30, rather than given a change of its
own. It was found by this change's bench work and it is small, but it is an aircraft change and is
held to the aircraft's rules: `M75_PRO_ELRS_V1.txt` is edited, and a fresh `diff all` is committed
so the file stays verifiable against a dated capture (`meteor75-pro/flight-config`). Until that
capture exists, `HANDOFF.md` records the divergence, as that same requirement allows.

`M75_PRO_SBUS_V1.txt` is left alone. The SBUS link has no telemetry path, so the line would do
nothing there, and the two files already differ in their receiver blocks; `feature TELEMETRY` is
treated as part of the ELRS receiver setup. The file headers and `meteor75-pro/README.md` that say
the files differ "only in the receiver block" are updated to name it.

The feature was applied through the CLI on the aircraft, not by re-pasting the config, so the
aircraft's accelerometer calibration was not disturbed.

## Risks / Trade-offs

- **[The Pavo20 cannot be arm-tested indoors]** → Its config has
  `gps_rescue_allow_arming_without_fix = OFF` and `gps_rescue_min_sats = 8`
  (`PAVO20PRO2_GPS_RESCUE_TUNING.txt`), so at `2025.12.2` it sets `ARMING_DISABLED_GPS` without a
  fix (`core.c:400-406`). On the bench, the Pavo20's ARM check is the Modes tab showing ARM in range
  plus `status` listing `GPS` as the *only* arming-disable flag. The actual arm is done on the
  Meteor75 on the bench, and on the Pavo20 outdoors with a fix, props off.
- **[The R1's rear paddles are pressed by accident]** → They carry only BEEPER and PREARM, both
  harmless in flight. The normal-grip scenario in the spec checks it.
- **[The R1's default mapping is still on the radio]** → Until the remap is done, SD is BEEPER and
  PREARM is on whatever the default puts on CH7. Nothing is flown on the R1 before the bench check
  passes on that aircraft.
- **[3-position outputs miss a band]** → The Meteor75's CH9 bands are 900–1200 / 1375–1675 /
  1800–2100, the narrowest in the fleet. Output Range and Center Point stay at defaults; the bench
  check reads the three values.
- **[A switch works backwards]** → Channel Reverse on that channel only; ARM must read above 1700
  when up.

## Migration Plan

None. The V12 is untouched and keeps working throughout. Rolling back is picking up the V12.

## Open Questions

Untested on hardware, and what settles each:

- **The full R1 channel map on each aircraft.** Settled by the bench check in `tasks.md` §3, per
  aircraft, over USB. Nothing is flown on the R1 until it passes on that aircraft.
- **Arming on the R1.** Bench on the Meteor75; outdoors with a fix on the Pavo20; props off both
  times. Performed by the user.
- **Flying on the R1.** A bench pass is not a flight. First flight in open space, hovering, cycling
  modes and rates, then disarm on SA. Performed by the user.
- **GPS Rescue triggered from the R1.** Not a new unknown — rescue is untested in the air on any
  radio (`pavo20-pro-ii/FAILSAFE.md`), and that procedure governs. The R1 adds only the question of
  whether SD reaches AUX 6, which the bench check settles.
- **Whether *Find Drone* only shows a real fix.** The manual says it needs ≥6 satellites. The GPSQR
  widget's history is that a position without a fix is plausible and wrong (a point in Mali, 2026-09-03).
  Settled by opening *Find Drone* indoors with the Pavo20 powered and no fix: it must refuse or show
  no position. **Left untested by the user's choice, 2026-10-01** — Find Drone will only be used
  while the GPS is working. Recorded in the R1 document with the reason it still matters.
- ~~Whether the R1 has battery and link-quality alarms.~~ **Resolved 2026-10-01: it has them**
  (user). Thresholds not recorded.
- **The R1's ELRS firmware version.** Known to link to the 3.5.6 receivers. The version matters only
  for the Full-Res channel tables, which D4 avoids. Read it off the radio for the record.
