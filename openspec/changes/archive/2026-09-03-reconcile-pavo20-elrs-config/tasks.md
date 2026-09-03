## 1. Remove the stale calibration

- [x] 1.1 Delete `set acc_calibration`, `set acc_trim_pitch` and `set acc_trim_roll` from
      `pavo20-pro-ii/PAVO20PRO2_ELRS_V1.txt` (lines 103-105) and add a comment in their place
      saying the aircraft's own calibration is authoritative and a re-level is required after a
      paste. Verify `grep -c "^set acc_" pavo20-pro-ii/PAVO20PRO2_ELRS_V1.txt` returns 0.
      (Checked `^set acc_`, not bare `acc_`: the replacement comment names the settings it removed.)
- [x] 1.2 Do the same in `pavo20-pro-ii/PAVO20PRO2_SBUS_V1.txt` (lines 109-111). Verify the same
      grep returns 0 there.

## 2. Refresh the OSD layout

- [x] 2.1 Copy the 8 changed `osd_*_pos` integers verbatim from
      `dumps/BTFL_cli_backup_PAVO20PRO2_20260903_BETAFPVG473_V3 - current.txt` into
      `PAVO20PRO2_ELRS_V1.txt`: `gps_sats` 2101, `home_dist` 2093, `gps_speed` 2425, `gps_lat`
      3143, `gps_lon` 3111, `altitude` 2108, `core_temp` 3215, `sys_vtx_temp` 3247. Verify by
      diffing every `osd_.*_pos` line in the file against the capture — the two sets must be
      identical.
- [x] 2.2 Confirm all 8 values are >= 2048, so no element has been made invisible by the
      transcription. A value below 2048 is hidden per `docs/betaflight-reference.md`.
- [x] 2.3 Apply the same 8 values to `PAVO20PRO2_SBUS_V1.txt` and verify the same way. The OSD is
      a property of the aircraft, not of the receiver protocol, so the two files must agree.

## 3. Drop the inert lines

- [x] 3.1 Remove `set gps_auto_baud = OFF` from both Pavo20 configs, and replace the surrounding
      GPS comment block with one that states the *value* matters and the line does not — the
      BZ-181 still must not be switched to the UBLOX provider. Verify the comment survives and
      only the `set` line is gone.
- [x] 3.2 Remove `set rates_type = ACTUAL` (ELRS line 275, SBUS line 282) and
      `set auto_profile_cell_count = 0` on profile 2 (ELRS line 251, SBUS line 258) from both
      files. Verify each removed line is absent from the 2026-09-03 capture, confirming it equals
      the firmware default.
- [x] 3.3 Re-check that nothing else in either file restates a default, by comparing every `set`
      line in `PAVO20PRO2_ELRS_V1.txt` against the capture and listing any that the capture does
      not contain. Anything found is either removed or given a pinning comment.

## 4. Correct the documentation the baseline disproved

- [x] 4.1 Fix `pavo20-pro-ii/GPS_SETUP.md:880`, which says `auto_profile_cell_count` selects
      profile 1 on a 3S pack. Profile 0 is now `O4Pro3S` with `auto_profile_cell_count = 3`.
      Verify against the profile blocks in the 2026-09-03 capture.
- [x] 4.2 Add the required accelerometer levelling step to `pavo20-pro-ii/SETUP_GUIDE.md`, placed
      after the config paste and before the first flight. Verify it names the Configurator Setup
      tab action and says why no committed number can substitute for it.
- [x] 4.3 Note in `pavo20-pro-ii/README.md` that the committed configs deliberately carry no
      accelerometer calibration, so a reader does not "restore" one from an old dump.

## 5. Verify and record

- [x] 5.1 Confirm both edited configs still open and close correctly as CLI batches — the
      `batch start` / `defaults nosave` header and the `save` footer intact, and no
      `profile_name` or `rateprofile_name` over 8 characters. Verify by inspection; an over-length
      name aborts the whole batch at `save`.
- [x] 5.2 Run `git grep` for the redacted MCU ID across tracked files to confirm the edits
      introduced no per-board value. Expect no matches.
- [x] 5.3 Update `HANDOFF.md` item 1 to say the reconcile is done and that it is **verified on
      paper only** — the ELRS config has not been re-pasted, so the round-trip in the OSD
      requirement is still outstanding. Record what would confirm it: a fresh `diff all` after the
      next paste, for any reason.
- [x] 5.4 Leave `PAVO20PRO2_SBUS_V1.txt` recorded in `HANDOFF.md` as never pasted or flown. The
      edits do not change its status, and it must not read as tested because it was touched.
