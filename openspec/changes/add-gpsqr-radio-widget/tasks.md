## 1. Land the widget as shipped

Commit the unmodified file first so the review fixes read as a diff against what has been flying.
Do not squash groups 1 and 2 together.

- [x] 1.1 Create `radio/WIDGETS/GPSQR/main.lua` from `C:\Users\ezagv\Downloads\GPSQR_widget.zip`, byte-identical to the archive; verify with `unzip -p` piped to `diff -` against the committed file, expecting no output
- [x] 1.2 Add `gpsqr_last.txt` and `LOGS/` to `.gitignore`; verify by touching `radio/WIDGETS/GPSQR/gpsqr_last.txt` and confirming `git status --porcelain` does not list it, then deleting it
- [x] 1.3 Commit this state on its own, with a message saying it is the as-shipped widget and that later commits modify it; verify `git show --stat HEAD` lists only the two files above

## 2. Apply the four code-review fixes

One fix per commit or one commit with all four — but each fix must be separately identifiable in
the diff. Do not refactor anything not listed here.

- [x] 2.1 Pin the QR code to black-on-white: add `color = BLACK, bgColor = WHITE` to both `qrcode` elements in `buildUI` (wide branch and portrait branch); verify by reading back that neither element relies on a theme default, and that the `BgColor`/`TxtColor` options still apply only to the panel and labels
- [x] 2.2 Bound the SD retry: in `saveFix`, stamp `w.lastSave = getTime()` and clear `w.needsSave` whether or not `io.open` returned a handle, so a failed write backs off for `SAVE_TICKS` like a successful one; verify by reasoning through the case `/LOGS/` absent — the rate-limit test in `poll` must be false for 10 s after a failure. Confirm on the radio in task 4.3
- [x] 2.3 Keep the status line on square zones: replace the `showText = (H - W) >= 24` gate so the status is always rendered, shrinking the QR to make room instead of dropping it; verify the QR still fits by checking the arithmetic for the square case (`W == H`) yields a positive `size` at least as large as the minimum from 2.4
- [x] 2.4 Floor the QR dimension: clamp `size` to a documented minimum in both layout branches and fall back to a text-only layout below it, so `lvgl.qrcode` is never handed a non-positive `w`/`h`; verify by walking the smallest zone the radio offers through both branches
- [x] 2.5 Update the header comment block in `main.lua` to state the black-on-white behaviour as implemented rather than assumed, and to note the file is version-controlled in the FPV repo; verify the comment no longer claims anything the code does not do

## 3. Documentation

- [x] 3.1 Write `radio/README.md` from the bundled README, keeping §1 install, §2 telemetry discovery, §4 battery/mAh alarms, §6 TX power and the RQly warning, §7 field workflow — and replacing §3 and §5 with cross-references to `pavo20-pro-ii/GPS_SETUP.md` and `pavo20-pro-ii/FAILSAFE.md`; verify no Betaflight setting value or firmware version appears under `radio/` except via cross-reference, by grepping the file for `set `, `UBLOX`, `gps_rescue` and `4.5`
- [x] 3.2 Add a short section to `radio/README.md` recording that §3 and §5 were removed and why, in the repo's convention of keeping the disproven thing on the page — §3's UBLOX/auto-baud advice is wrong for the Pavo20's BZ-181, §5 cited Betaflight 4.4/4.5 against a fleet on 2025.12.2 and gave rescue values differing from `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt`; verify the removed advice is quoted, not just referred to
- [x] 3.3 State in `radio/README.md` that a full-screen zone is required until the coordinate-origin question in `design.md` is settled, and that the displayed fix is the last one *received by the radio*, not where the quad came to rest; verify both caveats are present and neither claims an accuracy figure that has not been measured
- [x] 3.4 Write `radio/CODE_REVIEW.md`: the four fixed defects with the EdgeTX reference that establishes each, the findings deliberately not fixed (torn save file on truncating write, `getTime()` reset across boot, `update()` not stamping `lastBuild`, wide-layout text column ~88 px against a comment claiming ~94), and the items checked and found sound (the `-?` Lua pattern in `loadSaved` is correct — `-` at the start of a pattern item is a literal; the `hasFix` null-island test; the 5 s rebuild interval; `getValue` returning a non-table when the sensor is absent); verify every "not fixed" entry states its field consequence or says it has none
- [x] 3.5 Document `set report_cell_voltage = ON` in `radio/README.md` as a per-aircraft step the user applies, with the confirming observation (`RxBt` reads ~3.8 V on a charged 4S pack, not ~15.4 V), and state explicitly that no committed `.txt` config was changed; verify no `.txt` under any aircraft folder is modified by this change (`git diff --name-only` shows no `*.txt`)
- [x] 3.6 Add `radio/` to the layout block and the fleet table in the root `README.md`, and a "Things learned the hard way" entry for the theme-dependent QR colours; verify the layout block matches the actual tree
- [x] 3.7 Update `HANDOFF.md`: the recovery workflow now includes the widget, GPS telemetry to the radio is unverified on the Pavo20, and the widget's usefulness is gated on the still-unconfirmed first outdoor cold-start fix; verify the new text distinguishes verified from untested in the same terms as the existing "Verified vs not verified" section
- [x] 3.8 Update `CLAUDE.md` so its "What this is" section no longer says nothing here runs — one Lua file now executes on the radio — and note the radio/aircraft documentation split; verify the layout description matches the tree and that the "Not source code" framing still holds for the aircraft folders

## 4. Verify on the radio

Nothing in this repo can test a Lua widget. All of this is the user, on the V12 MAX, and the change
is not archivable until 4.1–4.4 are done.

- [ ] 4.1 Copy `radio/WIDGETS/GPSQR/main.lua` to the SD card root path `/WIDGETS/GPSQR/main.lua`, restart the radio, and confirm the widget loads without a Lua error and shows "Waiting for GPS fix..." with no drone powered
- [ ] 4.2 With a fix present, scan the QR with a phone on a **dark** theme and again on a **light** theme; verify both decode to the same `maps.google.com` URL on the first attempt. Record in `CODE_REVIEW.md` whether the shipped version also scanned on the dark theme, which settles whether 2.1 was a repair or insurance
- [ ] 4.3 Rename `/LOGS/` on the card, run the widget with a live fix for a minute, restore the folder; verify the radio does not stutter and no Lua error appears — this is the observable consequence of 2.2
- [ ] 4.4 Receive a fix, power the radio off and on with the drone unpowered; verify the widget shows the same coordinates marked `SAVED`, and that `/LOGS/gpsqr_last.txt` contains one `lat,lon` line
- [ ] 4.5 Assign the widget to a half-screen zone with a fix present; verify whether the QR renders inside the zone or at the screen origin, and record the answer in `design.md` under Open Questions — this settles the coordinate-origin question and determines whether a follow-up change is needed
- [ ] 4.6 On a square zone, verify the status indicator is visible alongside the QR — this is the observable consequence of 2.3
- [ ] 4.7 On the Pavo20 outdoors: Delete all sensors → Discover new sensors with the aircraft powered; verify `GPS`, `Sats` and `Alt` appear and the widget comes alive. If they do not, stop and record it — the widget is FireFly25-only until that path works

## 5. Close out

- [ ] 5.1 Fold the answers from 4.2, 4.5 and 4.7 back into `design.md` Open Questions and `HANDOFF.md`, moving each from untested to verified or to a named outstanding item; verify no Open Question still reads as unanswered when it was in fact answered
- [x] 5.2 Run `openspec validate --strict add-gpsqr-radio-widget` and confirm it passes
- [ ] 5.3 Delete the original ZIP from `Downloads/` only after 4.1 confirms the committed copy loads on the radio; verify `radio/WIDGETS/GPSQR/main.lua` is committed and pushed first
