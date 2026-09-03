## Context

See `proposal.md` — Why. Constraints that shape the approach:

- **The widget already runs on the user's radio.** This is not a greenfield implementation. The
  shipped `main.lua` (7.3 KB, 212 lines) works well enough that the user has been flying with it.
  Every change is a modification to something already in service, so the bar for touching a line
  is that leaving it alone has a plausible failure mode in the field.
- **There is no way to test EdgeTX Lua off the radio.** No emulator is set up here, no test
  harness exists, and the repo has no test suite by design. Verification is: copy to the SD card,
  look at the screen, point a phone at it. Same shape as the Betaflight configs.
- **EdgeTX behaviour is version-dependent in the same way Betaflight's is.** The widget declares
  `useLvgl = true` and requires 2.11+. The LVGL Lua API is recent and its documentation is thin in
  exactly the places that matter here.
- **The repo has never held executable code.** `CLAUDE.md` opens with "Not source code. Nothing
  here builds, runs or has tests." A Lua file that the radio executes is a genuine first, and the
  layout and review conventions have to be established rather than followed.
- **`openspec/specs/` is empty.** This change seeds it, so the capability path also sets a
  precedent for the aircraft specs that HANDOFF.md item 3 anticipates.

## Goals / Non-Goals

**Goals:**

- Get the widget under version control at a path that copies to the SD card without rearranging.
- Fix the defects that would bite in the field, and only those.
- Leave a record of what was reviewed and found sound, so the next reader does not repeat it.
- Separate radio-side documentation from aircraft-side documentation permanently, not just for
  this file.

**Non-Goals:**

- **Not a rewrite.** The widget's structure — poll in both `refresh` and `background`, rate-limited
  rebuild, SD persistence — is sound and stays.
- **No new features.** No compass bearing, no distance-to-drone, no waypoint list, no multi-fix
  history. Each is defensible and each is a separate change.
- **No aircraft config changes.** `report_cell_voltage` is documented as a step for the user, not
  written into a committed `.txt`.
- **Not adding a Lua toolchain.** No linter, no CI, no emulator. The repo stays a documentation
  repo that happens to contain one script.
- **Not fixing `meteor75-pro/README.md`**, which is a stale copy of an old `CLAUDE.md` rather than
  a README. Real, pre-existing, and unrelated to this change.

## Decisions

### Place the widget at `radio/WIDGETS/GPSQR/main.lua`, mirroring the SD card

The install instruction is "unzip into the root of the SD card". Mirroring that path means the
repo folder can be copied to the card directly, and a future second widget or a `SOUNDS/` folder
drops in beside it without rework.

*Alternative — `firefly25/`:* the bundled README was written for that aircraft. Rejected: the
V12 MAX is bound to all three quads, and the widget's value is highest on the Pavo20, which is the
one with an untested rescue. Filing fleet-wide radio content under one airframe would hide it.

*Alternative — `docs/`:* rejected. `docs/` is reference prose and the path would not mirror the
card.

### Fix four defects; record the rest

The review found more than four things worth saying. Only these four change code, on the test of
"is there a plausible field failure":

1. **QR colours unset.** `lvgl.qrcode` leaves `bgColor` at `COLOR_THEME_SECONDARY3` and, via the
   common object settings, `color` at `COLOR_THEME_SECONDARY1` (luadoc.edgetx.org, EdgeTX 2.11).
   Both are theme variables. The bundled README states "The QR code itself always stays
   black-on-white — scanners need the contrast", which the code does not implement. Fix: pass
   `color = BLACK, bgColor = WHITE` on the qrcode element. Two added keys.
2. **Unbounded SD retry.** In `poll()`, `saveFix` sets `w.lastSave` only inside the `if f then`
   branch. If `io.open(SAVE_PATH, "w")` fails — `/LOGS/` missing, card absent, card full — then
   `needsSave` stays true and `lastSave` stays nil, so the rate-limit test
   `w.lastSave == nil or getTime() - w.lastSave > SAVE_TICKS` passes every time and a card open is
   attempted on every poll. `poll()` runs from `refresh`, i.e. per frame. Fix: stamp `lastSave`
   whether or not the open succeeded, so a failure backs off for the same 10 s as a success.
3. **Status suppressed on square zones.** The portrait branch gates the status line on
   `showText = (H - W) >= 24`. A square zone gives `0 >= 24` false, so the widget renders a QR and
   nothing else — no `LIVE`, no `SAVED`, no age. That is the one piece of information that
   distinguishes a fresh fix from one restored from a previous flight. Fix: when the zone cannot
   fit the status below the QR, shrink the QR to make room rather than dropping the status.
4. **Unguarded dimension arithmetic.** `size` is derived by subtraction (`W - 100`, `H - 2*pad`)
   with no floor. Small zones can produce a non-positive `size`, and the EdgeTX reference requires
   `w` and `h` to be equal and positive for a valid code. Fix: floor the QR at a minimum and fall
   back to a text-only layout below it.

Everything else — the layout heuristics, the 5 s rebuild interval, the sensor lookup by name, the
`hasFix` null-island test, the Lua pattern in `loadSaved` (which is correct: `-` at the start of a
pattern item is a literal, so `-?` is an optional minus) — is left alone and recorded in
`radio/CODE_REVIEW.md` as reviewed and sound. The review file exists so the next reader knows the
difference between "not looked at" and "looked at and fine".

*Alternative — fix everything found:* rejected. Three findings (see Risks) have no field
consequence and each edit is a chance to break something that currently flies.

### Keep the review as a committed document, not just commit messages

`git log` is the wrong place for "this was checked and is correct". The repo's style already does
this — `README.md` has a "Things learned the hard way" section, and `GPS_SETUP.md` keeps disproven
hypotheses on the page. `CODE_REVIEW.md` follows that: findings with severity, what was changed,
what was deliberately not changed and why, and the one question the documentation cannot answer.

### Split the README along the radio/aircraft line

`radio/README.md` keeps §1 (install), §2 (telemetry discovery), §4 (battery and mAh alarms), §6
(TX power and the RQly warning), §7 (field workflow). These are radio-side, identical across the
fleet, and have no counterpart elsewhere in the repo.

§3 (GPS module configuration) and §5 (GPS Rescue) become cross-references. §3's advice — UBLOX with
auto-baud — is actively harmful on the Pavo20: the BZ-181 never answers a UBX `MON-VER`, so the
driver cannot leave `DETECT_BAUD` (`gps.c` at Betaflight 2025.12.2). §5 cites Betaflight 4.4/4.5
against a fleet running 2025.12.2, and gives return-altitude and min-sats values that differ from
the ones actually in `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt`. Both point at the aircraft folder
instead.

The removals get a short note saying what was removed and why, in the repo's convention of keeping
the disproven thing on the page.

*Alternative — keep verbatim with a warning banner:* rejected. A reader who scrolls past the
banner gets the wrong GPS advice, and the repo would then hold two contradictory GPS Rescue
procedures.

### Per-cell voltage stays documented, not configured

`set report_cell_voltage = ON` is what makes one 3.5 V/cell alarm threshold work across a 1S whoop
and a 4S cinewhoop. It is correct and worth doing, but it is an aircraft config change and belongs
in a change that also updates the committed `.txt` files and gets flown. Here it is written up as
a step with the observation that confirms it (`RxBt` reads ~3.8 V on a charged 4S pack rather than
~15.4 V).

### Capability path `radio/gpsqr-widget`

No existing specs to follow. The two-level path establishes `radio/` against future per-aircraft
paths, matching the folder layout the repo already uses. A flat `gpsqr-widget` would work today
and read badly once aircraft specs land.

## Risks / Trade-offs

**The coordinate origin is unresolved and a fix could break a working widget** → The EdgeTX LVGL
reference says `x`/`y` are relative to "the parent object" without saying what a widget's parent
is, and its own LVGL widget example offsets labels by `wgt.zone.x` — implying the parent is the
screen, not the zone. The shipped widget uses zone-relative coordinates. If the parent is the
screen, the widget only renders correctly full-screen, which is what the README recommends and
probably what has been flown. Mitigation: change nothing here. Test on the radio in a half-screen
zone and only then decide. A speculative `+ zone.x` would break the full-screen case if the
current behaviour is already right.

**Editing a script that currently works** → Four small, independent edits, each stated in
`CODE_REVIEW.md` with what it changes. The shipped file is preserved verbatim in git history via
the first commit, so `git show` recovers it. Do not squash those commits.

**Torn save file** → `saveFix` opens with `"w"`, truncating before the new coordinates are
written. Losing power in that window leaves an empty or partial file and the previous fix is gone
— in the scenario the feature exists for. Accepted, not fixed: the EdgeTX Lua io API has no
rename, so an atomic write would mean an alternating two-file scheme, and the exposure is
sub-millisecond against a 10 s write interval. Recorded in `CODE_REVIEW.md`.

**`getTime()` resets on radio boot** → Ages are computed as differences against a tick counter that
restarts at power-on. Not a live bug, because a restored fix is flagged `fromFile` and shows
`SAVED` rather than an age. It would become one if a future change reported an age for restored
fixes.

**`update()` does not stamp `lastBuild`** → An options change rebuilds the UI and can be followed
immediately by another rebuild from `refresh`. Two rebuilds while the user is in the settings
screen. No field consequence; recorded, not fixed.

**Documentation drift between `radio/` and the aircraft folders** → The whole reason §3 and §5 are
being removed. The spec requirement "Radio-side documentation SHALL NOT restate per-aircraft flight
controller settings" is what keeps it from recurring, which is why it is a spec and not just a note
in this design.

**Position data in a public repo** → The repo is public and the README warns about redacting
`mcu_id`. `/LOGS/gpsqr_last.txt` holds real coordinates, usually the user's home or flying field.
Mitigation: add `gpsqr_last.txt` to `.gitignore`, and never commit an example with real
coordinates — the documentation uses an obviously synthetic pair.

## Migration Plan

1. Commit the shipped `main.lua` unmodified first, so the review fixes are a readable diff against
   what has actually been flying.
2. Apply the four fixes in a second commit.
3. Copy `radio/WIDGETS/GPSQR/main.lua` to the SD card root, replacing the installed copy.
4. Verify on the radio (below) before trusting it.

Rollback is `git show` of the first commit, written back to the card. There is nothing to
uninstall — the widget is one file plus `/LOGS/gpsqr_last.txt`.

## Open Questions

These are deliberately left untested. Each names what would settle it. The user performs all of
them — the radio and the aircraft are not accessible from here.

**Is a widget's LVGL coordinate origin the zone or the screen?** Assign the widget to a
half-screen zone with a fix present. If the QR draws inside the zone, coordinates are
zone-relative and the shipped code is correct. If it draws at the screen's top-left or overlaps
the neighbouring widget, every `x`/`y` needs `+ w.zone.x` / `+ w.zone.y`. A full-screen zone
cannot answer this — the origin is `0, 0` and both readings agree. Until this is answered,
`radio/README.md` must keep recommending a full-screen zone.

**Does the black-on-white fix actually scan on a dark theme?** The defect was found by reading the
EdgeTX API reference, not by observing a failed scan. Set the radio to a dark theme, display a
fix, and scan with a phone — before the fix and after. If the shipped version already scanned
fine, the theme's `COLOR_THEME_SECONDARY3` happens to be light and the fix is insurance rather
than a repair. Either way it is worth having; the point is to record which it was.

**Does the widget still show the position after a genuine failsafe?** Everything so far is bench
reasoning. The real test: fly out, cut the link deliberately in a safe place (props off on the
bench for the first pass, per `pavo20-pro-ii/FAILSAFE.md`), and confirm the widget holds the last
fix and starts counting the age up rather than blanking or freezing at `LIVE`.

**Is the saved fix accurate enough to walk to?** The widget shows the last fix *received by the
radio*, which is the last fix transmitted before the link died — not where the quad came to rest.
A quad that tumbles from 40 m lands some distance from that point, and the Pavo20's first outdoor
cold-start fix has not been confirmed at all (`HANDOFF.md`). Establish the real-world offset by
landing normally, noting the widget's coordinates, and pacing out the error. Until that number
exists, the widget's accuracy claim is unquantified and the documentation must say so.

**Does GPS telemetry reach the radio on the Pavo20 at all?** The widget needs a `GPS` sensor in
the CRSF stream. This is confirmed on the FireFly25, which the widget was written against. On the
Pavo20 it is untested — the GPS itself was only made to work on 2026-09-01, and telemetry to the
radio is a separate path from the OSD. Settle it by running Delete all sensors → Discover new
sensors with the Pavo20 powered outdoors and checking that `GPS`, `Sats` and `Alt` appear.
