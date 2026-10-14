# Tasks

## 1. Baseline and configuration

- [x] 1.1 Add the dated baseline under `meteor75-pro-ii/dumps/`. Compare it with the supplied capture, with board identity/signature values redacted.
- [x] 1.2 Confirm all new CLI names against source at `eb2bb5a33` or actual `get` output. Resolve the throttle-hover name and conditional OSD settings.
- [x] 1.3 Create `M75_PRO_II_ELRS_V1.txt` from the Pro II baseline. Compare the tune, filters, orientation, battery, motor, receiver, video, telemetry, and failsafe settings.
- [x] 1.4 Add the agreed R1 mode assignments. Review each AUX line against the control table and remove the factory HORIZON/CH7 TURTLE assignments.
- [x] 1.5 Add SC Stock / Cine / Park selection. Compare all rate and throttle values with the spec and confirm final profile selections.
- [x] 1.6 Transfer supported v1 OSD positions and visibility. Compare only layout values, retain Pro II alarm thresholds, and document unsupported elements.
- [x] 1.7 Review the reusable configuration structure. Confirm the batch/reset/save commands, valid name lengths, and absence of board identity/calibration values.

## 2. Setup documentation and fleet references

- [x] 2.1 Add the aircraft README with hardware, provenance, control tables, rate comparison, and file index. Compare each value with its cited evidence.
- [x] 2.2 Add `SETUP.md` with O4 activation, goggles link, and R1 phrase procedures. Verify DJI steps against official documentation and exclude credentials.
- [x] 2.3 Add configuration application, calibration, rollback, and verification procedures. Make each hardware result pending until the pilot supplies its observation.
- [x] 2.4 Update root and radio links plus the OpenSpec aircraft inventory. Verify links and keep aircraft-specific values in the aircraft folder.
- [x] 2.5 Add the Pro II state to `HANDOFF.md`. Separate source review, CLI syntax validation, bench verification, and flight verification.

## 3. Source review

- [x] 3.1 Review the configuration against the baseline, spec, and firmware source. Record every intended difference and expected omission from `diff all`.
- [x] 3.2 Validate this OpenSpec change with `openspec validate configure-meteor75-pro-ii --strict`. Record source-review results without a hardware verification claim.

## 4. O4 activation and CLI syntax validation — pilot

Remove the propellers before each powered bench procedure. Supply airflow across the powered O4 Air Unit.
These tasks require actual hardware observations. Codex must not mark them complete from file review.

- [x] 4.1 Activate the O4 Air Unit through DJI Assistant 2 with the pilot's account. The pilot reported activation complete on 2026-10-12.
- [ ] 4.2 Record DJI firmware versions and confirm a stable live image. The pilot reported the DJI Goggles 3 link complete on 2026-10-12.
  The pilot confirmed very good video on 2026-10-14. DJI firmware versions remain unrecorded.
- [x] 4.3 Confirm the R1 link and battery telemetry. The pilot confirmed CH1–CH9 responses and correct battery indication on the radio on 2026-10-12.
- [x] 4.4 Confirm build-specific settings through `get` before application. The 2026-10-12 19:36:23 capture confirms every required setting; no unsupported element remains.
- [x] 4.5 Apply and save the configuration after the corrected input and batch restart. The 2026-10-12 19:59:33 capture confirms the configuration after USB restart.
- [x] 4.6 Calibrate the aircraft and verify the 3D model. The pilot confirmed successful calibration, correct roll/pitch tilt responses, and return to level on 2026-10-12.
- [x] 4.7 Compare and preserve the 2026-10-12 19:59:33 capture. All 134 explicit settings match, with 28 expected default omissions and actual calibration.

## 5. Bench verification — pilot

Keep the propellers removed. Use a battery when a check needs the air unit or motors powered.

- [x] 5.1 Verify CH1–CH9 and the R1 mode assignments. The pilot confirmed the mode ranges and adjustment ranges respond correctly on 2026-10-12.
- [x] 5.2 Verify the PREARM condition from a fresh boot. Confirm refusal without PREARM, successful SF/SA arming, and immediate motor stop with SA low.
  The pilot confirmed refusal without PREARM on 2026-10-14 after the fresh-boot procedure.
  The pilot confirmed the normal SF/SA arm/disarm sequence through the reported flights and response to the follow-up question.
- [x] 5.3 Operate SC through all three positions. Confirm Stock / Cine / Park names, rate values, and identical stock throttle settings through readback.
  The pilot confirmed all three displayed names on 2026-10-14. The saved configuration capture confirms their rate and throttle values.
- [ ] 5.4 Connect a freshly charged intended 1S pack. Confirm 1S detection, PID profile 0, battery voltage, and R1 `RxBt` telemetry.
  The 2026-10-14 capture confirms PID profile 0. The pilot confirmed USB power only, with no battery connected.
  The pilot reported flights that day with no observed battery problems.
  The later status confirms 3.82 V and `1S battery - OK`. The pilot confirmed that the R1 was off during this capture.
  Radio battery telemetry was confirmed on 2026-10-12. Pack charge state at this capture remains unconfirmed.
- [ ] 5.5 Examine motor order, direction, and telemetry with the propellers removed. Confirm DSHOT_TELEM clears and every motor responds correctly.
  The 2026-10-14 battery-powered status has no DSHOT_TELEM flag. Individual motor order, direction, and telemetry observations remain pending.
- [ ] 5.6 Read the saved failsafe procedure and perform a link-loss check. Record the expected and observed motor response before flight.
  The 2026-10-14 readback confirms `failsafe_procedure = DROP`.
  The pilot requested that the link-loss bench test be skipped on 2026-10-14. The response remains untested; this task stays unchecked.
- [x] 5.7 Examine the OSD in the O4 goggles. Confirm supported v1 positions, visibility, readable warnings, and the selected rate name.
  The pilot confirmed the v1 layout and Stock / Cine / Park display on 2026-10-14, with no reported OSD problems.

## 6. Flight verification and evidence — pilot

- [ ] 6.1 Complete a short first flight after all required bench checks pass. Record Angle behaviour, Acro control, motor temperatures, and video stability.
  The pilot reported indoor Stock/Cine flights on 2026-10-12 with 580 mAh packs. Throttle precision was difficult.
  On 2026-10-14, the pilot reported normal motor temperatures and very good video in response to the flight questions.
  The pilot strongly preferred the wide camera and stabilization over the Meteor v1. Angle/Acro observations remain unrecorded.
- [ ] 6.2 Fly each SC rate profile and report the control response. Record whether Stock, Cine, and Park work acceptably with the stock throttle curve.
  Stock felt better indoors than Cine; both flights used 580 mAh packs.
  On 2026-10-14, the pilot reported that Stock felt perfect outdoors. Outdoor Cine/Park observations remain pending.
  Keep current settings. Any later rate or throttle adjustment will use a separate change.
- [x] 6.3 Commit the supplied final capture and dated verification results. Update the aircraft documentation and handoff; leave unperformed checks incomplete.
  The repository commit includes the captures, dated results, aircraft documentation, synced main spec, and archive on 2026-10-14.
  The pilot requested archival with the remaining hardware observations unverified. Six hardware tasks remain unchecked.
