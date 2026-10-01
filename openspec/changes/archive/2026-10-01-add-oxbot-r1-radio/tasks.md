# Tasks

## 1. Record the V12 MAX

- [x] 1.1 Read the V12's own names for the two front buttons used as BEEPER and GPS Rescue (the user called them "SE4" and "SE6") off the radio's channel monitor or mixer screen, and verify the names in `radio/v12-max/README.md` match what the radio displays
- [x] 1.2 Write `radio/v12-max/README.md`: the switch-to-channel table (SA ARM, SB modes, SD PREARM momentary, button 4 BEEPER, SC rates, button 6 GPS Rescue), the current ELRS settings (`333Hz Full`, `12ch Mixed`) with a link to `pavo20-pro-ii/BINDING_GUIDE.md` for why, and links to the widget and alarm sections of `radio/README.md`; verify it states no mode range and links to each aircraft's channel table instead

## 2. Write the Oxbot R1 document

- [x] 2.1 Write `radio/oxbot-r1/README.md` with the assignment table (CH5 SA, CH6 SB, CH7 SF, CH8 SE, CH9 SC, CH10 SD) and the V12 column beside it; verify every channel the aircraft read appears exactly once and each function links to `pavo20-pro-ii/BINDING_GUIDE.md` / `meteor75-pro/README.md` rather than restating ranges
- [x] 2.2 Add why CH10 is on SD and not a paddle, and why PREARM is on SF, pointing to `openspec/specs/radio/channel-mapping/spec.md`; verify the rescue rationale cites the 2026-09-03 field trigger
- [x] 2.3 Add the R1 settings: one model for both aircraft (design D5), a standard packet rate (250Hz, per `BINDING_GUIDE.md`), Telem Ratio not Off, Model Match off, Throttle Lock off with the reason, Output Range and Center Point at defaults; verify each setting names the R1 menu path from the Quick Start Guide
- [x] 2.4 Add a pairing section: the fleet pairs by binding phrase only, entered on the radio, and the R1's *Bind* button is not used (design D8); verify it records that phrase pairing was confirmed with both aircraft on 2026-09-30 and makes no claim about what bind mode does
- [x] 2.5 Add the bench check from §3 as a numbered procedure, including the Pavo20's no-fix arming block and how to read it with `status`; verify the procedure needs only USB and Configurator, no goggles
- [x] 2.6 Add a "What is not verified" section mirroring the Open Questions in `design.md` (Find Drone without a fix, alarms, first flight, ELRS version); verify nothing on the page claims a flight result

## 3. Bench check on the aircraft (performed by the user, props off)

- [x] 3.1 On the R1's single model, set Mapped Switch to CH5 SA, CH6 SB, CH7 SF, CH8 SE, CH9 SC, CH10 SD, and a standard packet rate; verify on the R1's *View Channels* page that each switch moves only its channel
- [x] 3.2 Meteor75 over USB, Receiver tab: SA → AUX1 above 1700 when up; SB → AUX2 three values, low under 1300 and high above 1700; SF → AUX3 high only while held; SE → AUX4 high and stays high after release; SC → AUX5 three values inside 900–1200 / 1375–1675 / 1800–2100. Verify by recording the values read
- [x] 3.3 Meteor75: hold SF, throttle at minimum, flip SA, and verify the quad arms (Modes tab ARM active, motors spin); flip SA down and verify they stop. If it does not arm, record the `status` *Arming disable flags* line
- [x] 3.4 Pavo20 over USB, Receiver tab: repeat 3.2's checks for AUX1–AUX5, then SD → AUX6 above 1700 and GPS RESCUE lit on the Modes tab; verify AUX6 is not parked at exactly 1500
- [x] 3.5 Pavo20 indoors: SD down, hold SF, flip SA, run `status`; verify `GPS` is the only arming-disable flag. Then SD up and verify `RESC` appears
- [x] 3.6 Both aircraft, normal flying grip: squeeze and brush SE and SF; verify AUX6 never changes
- [ ] 3.7 Pavo20 powered indoors with no fix: open R1 *Find Drone*; verify it refuses or shows no position, and record what it showed — **not done, by the user's choice (2026-10-01)**; recorded as unverified in `radio/oxbot-r1/README.md`

## 4. Meteor75 telemetry (design D9)

- [x] 4.1 Enable `feature TELEMETRY` on the Meteor75 and `save` (done by the user 2026-09-30); verified by `RxBt` appearing on the R1
- [x] 4.2 Add `feature TELEMETRY` to the feature block of `meteor75-pro/M75_PRO_ELRS_V1.txt` with a comment citing why it cannot be left to a default, and update the "differ only in the receiver block" wording in both Meteor75 file headers and `meteor75-pro/README.md`; verify `grep -c "^feature TELEMETRY" meteor75-pro/M75_PRO_ELRS_V1.txt` is 1 and 0 for the SBUS file
- [x] 4.3 Record in the Meteor75 section of `HANDOFF.md` that telemetry was off on every capture, was enabled 2026-09-30, and that the committed config diverges from the ` - current` capture by that one line until 4.4; verify the entry names the date and the capture it diverges from
- [x] 4.4 Take a `diff all` from the Meteor75 (user), commit it to `meteor75-pro/dumps/` dated 2026-09-30 with `mcu_id` redacted and suffixed ` - current`, and retitle the 2026-09-29 ` - current` capture; verify exactly one file carries ` - current`, the new one contains `feature TELEMETRY`, and it otherwise matches `M75_PRO_ELRS_V1.txt` as `HANDOFF.md` describes — then remove the divergence note from 4.3

## 5. Close out

- [x] 5.1 Edit `radio/README.md`: replace "One radio flies all three aircraft" with a radio index linking `v12-max/` and `oxbot-r1/`, and mark the widget, logical-switch alarm and ELRS Lua sections as V12/EdgeTX-only; verify every existing heading is still present so inbound links resolve
- [x] 5.2 Update the radio row of `HANDOFF.md`'s status table and add an Oxbot R1 section with the §3 results and dates; verify it separates bench-verified from flown
- [x] 5.3 Record in the R1 document whether the R1 has battery and link-quality alarms, once the user has checked, and if not, state it as a gap versus the V12; verify the Open Question in `design.md` is resolved or still marked open
- [x] 5.4 Run `openspec validate add-oxbot-r1-radio --strict` and verify it passes
