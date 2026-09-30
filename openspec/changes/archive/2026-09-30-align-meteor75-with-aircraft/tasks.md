# Tasks

## 1. Capture

- [x] 1.1 Copy `C:\Users\ezagv\Downloads\BTFL_cli_M75_PRO_20260929_212636_BETAFPVG473.txt` to `meteor75-pro/dumps/BTFL_cli_backup_M75_PRO_20260929_BETAFPVG473 - current.txt`, replacing the `mcu_id` value with `0000000000000000000000  # redacted - per-board hardware serial` as in the factory dump. If the Downloads file is gone, take a fresh `diff all` from the aircraft before anything is pasted. Verify: `git grep` for the real `mcu_id` (read from the Downloads file, never written into the repo) returns nothing, and the file's `adjrange`, `rateprofile` and `vbat_max_cell_voltage` lines match `design.md` Context
- [x] 1.2 Append the `serial` and `get serialrx_provider` output from `design.md` Context as a trailing comment block in the capture, dated 2026-09-29. Verify: the capture shows `serial 2 64` and `serialrx_provider = CRSF`

## 2. Configs

- [x] 2.1 Write `meteor75-pro/M75_PRO_ELRS_V1.txt`: header comments in the shape of `PAVO20PRO2_ELRS_V1.txt`; `batch start` / `defaults nosave`; board, feature, serial, beacon, `aux` and `adjrange` from the capture; `serial 2 64` and `set serialrx_provider = CRSF` pinned with a comment (design D4); master settings from the capture with `acc_calibration` removed and a comment in its place, plus `vbat_min_cell_voltage = 320` and `vbat_warning_cell_voltage = 333` (D3); profile 0 = the factory dump's GF 40mm block verbatim (D2); rate profiles 0–2 per D1 with no `throttle_limit_*`; end on `profile 0` / `rateprofile 0`; `save`. Verify: `grep -c "^set acc_"` returns 0; every `*_rc_rate` is below its `*_srate`; every profile and rate profile name is ≤ 8 characters; the file ends in `save`
- [x] 2.2 Write `meteor75-pro/M75_PRO_SBUS_V1.txt` from 2.1, changing only the receiver block per D4 (`serial 0 64`, `serial 2 0`, `serialrx_provider = SBUS`) and the header. Verify: `diff` between the two files shows only the header, the serial lines and `serialrx_provider`
- [x] 2.3 Delete `M75_hello_radio_v12.txt`, `M75_PRO_CLAUDE_CODE_V1.txt` and `M75_PRO_RADIOMASTER_POCKET_V1.txt` (D5). Verify: `ls meteor75-pro/*.txt` lists only the two V1 variants

## 3. Documentation

- [x] 3.1 Rewrite `meteor75-pro/README.md` as aircraft documentation, not a CLAUDE.md: hardware (BETAFPVG473, 4.5.1, DJI air unit on UART4, ELRS on UART3 / PB11, SBUS option on UART1 / PA10), which variant to paste, the AUX table and CH9 rate table from D1, the paste-in-chunks → save → calibrate accelerometer → `diff all` round-trip procedure, and the packs in use (Lava 2 LiHV 580/680 mAh, 4.35 V). Correct the mode IDs (0 = ARM, 1 = ANGLE, 13 = BEEPER, 35 = TURTLE, 36 = PREARM). Verify: no line in the README states a mode ID or UART that disagrees with the configs
- [x] 3.2 Correct `meteor75-pro/BINDING_GUIDE.md`: the receiver is on UART3, not UART2; retitle away from the Radiomaster Pocket, or state that the procedure is the same on the HelloRadio V12 MAX. Keep radio-side settings out of `radio/` per `openspec/specs/radio/gpsqr-widget/spec.md`. Verify: `grep -n UART2 meteor75-pro/BINDING_GUIDE.md` returns nothing
- [x] 3.3 Update `HANDOFF.md`: Meteor75 status becomes "configs rewritten 2026-09-29, not yet flown"; list design Open Questions 1–5 as outstanding; close the Meteor half of *Known gap: the rest of the fleet still commits calibration* (acc_calibration removed) and leave the FireFly25 half open. Verify: the fleet table no longer says "no outstanding work" for the Meteor75

## 4. Bench (pilot)

- [x] 4.1 Paste `M75_PRO_ELRS_V1.txt` in chunks, `save`, then Setup > Calibrate Accelerometer with the quad level. Verify: no CLI error lines; the aircraft reboots
- [x] 4.2 Take a fresh `diff all` and compare with the ELRS file. Verify: differences are only `acc_calibration`, `mcu_id`, `signature`, comments, and the pinned defaults `diff all` never prints (`serial 0 0`, `serial 2 64`, `serialrx_provider = CRSF`, empty `profile 1`-`3`); commit it redacted as the new `current` capture
- [x] 4.3 Plug in a freshly charged Lava LiHV pack, disarmed. Verify: OSD shows a 1S voltage immediately, `status` shows PID profile `GF 40mm` active, and cycling CH9 low/mid/high switches the OSD rate profile name through Cine/Park/Base (the 1/2/3 beeps are masked by the radio's sound effects). 2026-09-30: switching confirmed in flight by feel; battery voltage on plug-in checked by the pilot, "everything was as expected"

## 5. Flight (pilot)

- [x] 5.1 Hover in Angle, then fly Acro on CH9 low, mid and high. Verify: no oscillation; small centre-stick inputs give slow rotation on all three; motors not hot after a pack. Record the outcome and date in `HANDOFF.md` (design Open Questions 1–2). 2026-09-30: six packs flown on all three positions, no notable oscillation in wind, Angle take-off and landing fine; motor temperature not checked — closed by the pilot 2026-09-30 without that check
- [x] 5.2 Throttle chops and power loops on Base. Verify: the quad holds attitude at zero throttle without bobbing (Open Question 3); if not, note it for a separate dynamic-idle change rather than editing V1. 2026-09-30: pilot reports no complaints

## 6. SBUS variant (pilot, when the DJI RC is next used)

- [ ] 6.1 Bind the DJI RC, paste `M75_PRO_SBUS_V1.txt`, and check the Receiver tab. Verify: sticks move CH1–4 correctly and each switch moves CH5–CH9 as the AUX table expects; bench-arm with props off. Record the result in `HANDOFF.md` (Open Question 5). This task may remain open when the change is archived, if `HANDOFF.md` says so
