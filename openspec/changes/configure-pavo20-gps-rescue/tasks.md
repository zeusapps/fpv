## 1. Consolidate the work already in the working tree

These files are already edited but uncommitted. Verify rather than redo.

- [x] 1.1 Confirm the two-block split exists: `PAVO20PRO2_GPS_RESCUE_TUNING.txt` holds the
  parameters and `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt` holds exactly one `set` line. Verify with
  `grep -c '^set '` on each — expect 12 and 1 (11 plus the `ap_hover_throttle` line from 2.1).
- [x] 1.2 Confirm the arming line reads `GPS-RESCUE` with a hyphen in every file and document that
  references it. Verify `grep -rn 'GPS_RESCUE' --include=*.txt --include=*.md .` returns nothing
  outside `openspec/changes/archive/`.
- [x] 1.3 Confirm the GPSQR widget gates on `Sats` with a minimum count and reports a missing
  sensor distinctly from a low count. Verify `npx luaparse radio/WIDGETS/GPSQR/main.lua` parses and
  that each scenario in the `radio/gpsqr-widget` delta has a corresponding branch in `main.lua`.
- [x] 1.4 Confirm `HANDOFF.md` states the true current state — block 1 pasted, block 2 not, `aux 6`
  applied, failsafe on `DROP` — with no leftover claims that any of those is outstanding.
  *Superseded 2026-10-02: true when done; block 2 has since been applied — see 5.5–5.7.*

## 2. Correct the hover throttle reference

- [x] 2.1 Add `set ap_hover_throttle = 1340` to `PAVO20PRO2_GPS_RESCUE_TUNING.txt` with a comment
  citing `autopilot_multirotor.c:195-205` for why it is the throttle at rescue onset, and
  `thr_hover = 34` for where 1340 comes from. Verify the file still has no `batch start` and ends
  in `save`.
- [x] 2.2 Paste the line onto the aircraft and verify with `get ap_hover_throttle` returning `1420`
  — not by the paste appearing to succeed, per the `flight-config` read-back requirement.
  *Revised 2026-10-02: the target was `1340`. The 2026-10-01 rescue came home oscillating in
  altitude with `1340` set, and the pilot read hover at ~42% on a 4S 850 mAh pack, so the committed
  value is now `1420` — a measurement, which the `failsafe` delta says overrides the derivation.*
  *Done 2026-10-02: `get ap_hover_throttle` returned `1420`.*
- [x] 2.3 Record in `FAILSAFE.md` that the value is derived, not measured, and that a steady hover
  must be flown with the OSD throttle percentage read and the setting corrected to match before any
  rescue attempt. Verify the procedure names the OSD element and the 1000–2000 conversion.

## 3. Make the next attempt produce evidence

*Original premise, disproved on the aircraft 2026-09-20: "`feature BLACKBOX` is absent from the
capture, so `debug_mode` alone logs nothing." Both halves are wrong, and the task built on them
would have had the pilot run a command the CLI rejects and then believe logging was armed.
`feature BLACKBOX` does not exist at `2025.12.2` — it appears in none of the three lists `feature`
prints — and blackbox was already enabled via `blackbox_device = SPIFLASH`. What stopped the
2026-09-03 attempt recording was a **full flash**: `flash_info` reported `usedSize` equal to
`totalSize`.*

- [x] 3.1 Confirm blackbox is enabled by device, not by feature flag. `get blackbox_device` returns
  `SPIFLASH` and `feature` lists no `BLACKBOX` in Enabled, Available or Unavailable — both already
  observed 2026-09-20. Settle it by running `feature BLACKBOX` and confirming the CLI rejects the
  name. Record the flash size `flash_info` actually reports in `HARDWARE.md`.
- [x] 3.2 Set `debug_mode = RTH` and verify with `get debug_mode`. Note the previous value
  (`GYRO_FILTERED`) in `FAILSAFE.md` so it can be restored after testing.
  *Done 2026-10-02: `get debug_mode` returned `RTH`; `GYRO_FILTERED` is noted in `FAILSAFE.md` step 4.*
- [ ] 3.3 Free the flash, then size a full flight against the 16 MB it actually holds.
  **Download the existing contents before erasing** — the flash is full, so it holds logs from
  earlier flights, and the newest may cover 2026-09-03. *Not done: erased unread 2026-10-02
  (`usedSize` 16777216 → 0). The old logs are lost.* Then erase, arm on the bench props off for
  a timed 60 s, read `flash_info`, and confirm the used bytes extrapolate to a complete flight at
  `blackbox_sample_rate = 1/4` (allowed: 1/1, 1/2, 1/4, 1/8, 1/16; `pid_process_denom = 2` puts
  logging near 1 kHz). Lower the rate only if the measurement says it does not fit.
- [x] 3.4 Add erasing the flash before each rescue attempt to the test procedure in `FAILSAFE.md`,
  and add reading the `RTH` debug fields after it. Verify the procedure names the three slots and
  what each decodes to.

## 4. Align the documentation with the specs

- [x] 4.1 Reconcile `FAILSAFE.md` against the `pavo20-pro-ii/failsafe` delta: the DROP-until-proven
  rule, the two-block split with block 1 applied first, the trigger geometry table, and the
  instrumentation requirement. Verify every requirement in the delta has a corresponding passage.
- [x] 4.2 Correct the sanity-check passage to stop presenting `FS_ONLY` as protection against a
  failed switch test. State that the climb-failure path at `gps_rescue_multirotor.c:434-460`
  ignores the sanity mode and forces `RESCUE_LANDING` regardless. Verify no text claims a
  switch-induced rescue cannot disarm.
- [x] 4.3 Reconcile `radio/README.md` and `pavo20-pro-ii/BINDING_GUIDE.md` against the
  `radio/elrs-link` delta — the per-mode channel table at tag 3.5.6, the exactly-1500 signature,
  and the recorded `333Hz Full` / `12ch Mixed` setting. Verify the radio-side document states no
  Betaflight setting that differs between aircraft, per the existing `radio/gpsqr-widget` rule.
- [x] 4.4 Update `radio/CODE_REVIEW.md` to close the no-fix defect with the `Sats` sensor name and
  the field observation that confirmed it. Verify the entry records what was changed and what is
  still unverified on the radio.

## 5. Leave the arming step gated and verifiable

- [x] 5.1 Confirm `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt` lists the preconditions as a checklist that
  now includes the measured hover throttle and a logged, successful rescue. Verify it instructs
  `get failsafe_procedure` after pasting.
- [x] 5.2 Confirm the aircraft is left on `DROP`: `get failsafe_procedure` returns `DROP` and
  `feature`/`diff` show no `failsafe_procedure` line. This is the final state of this change.
  *Superseded 2026-10-02: the pilot applied block 2 and chose to keep it. The final state is
  `GPS-RESCUE` — see 5.5.*
- [x] 5.3 Record in `HANDOFF.md` what the 2026-09-03 attempt did and did not prove — switch
  reaches the state machine, home was set, GPS had a fix; nothing about whether the rescue can fly
  the aircraft — and that the next attempt is the pilot's, outside this change.
- [x] 5.4 Commit the change with the working-tree edits, and verify `openspec validate
  configure-pavo20-gps-rescue --strict` still passes.
- [x] 5.5 Read the failsafe procedure back off the aircraft. `get failsafe_procedure` returned
  `GPS-RESCUE` on 2026-10-02; the pilot chose to keep it after being told what is unproven.
- [x] 5.6 Before the next flight, apply `ap_hover_throttle = 1420` and read it back — this is 2.2.
  With the failsafe live, a real signal loss runs the rescue on whatever value is on the board.
- [x] 5.7 Rewrite `HANDOFF.md`, `FAILSAFE.md` and the header of `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt`
  to state that `GPS-RESCUE` is live, as an accepted risk, with the `DROP` revert. Keep the gate
  checklist, marked with which items were unmet when it was armed. Verify `grep -n DROP` across
  them finds no claim that the aircraft is currently on `DROP`.
