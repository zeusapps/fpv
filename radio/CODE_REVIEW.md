# Code review — GPSQR widget

Reviewed 2026-09-03, against `WIDGETS/GPSQR/main.lua` as shipped in `GPSQR_widget.zip`
(7260 bytes, 212 lines).

- As shipped, unmodified: commit `a3b2c6d`
- After the fixes below: commit `453447c`

`git diff a3b2c6d 453447c` is the whole of what changed from the version that had been flying.

Claims about EdgeTX behaviour are cited to the EdgeTX Lua reference (luadoc.edgetx.org) read at
**EdgeTX 2.11**, which is the version the widget declares as its minimum. The same discipline the
aircraft docs use for Betaflight: the API reference decides, not memory.

**None of this has been verified on the radio yet.** Everything below is source reading and
arithmetic. Tasks 4.1–4.6 of `../openspec/changes/add-gpsqr-radio-widget/tasks.md` are the
hardware checks, and until they are done the fixes are argued, not demonstrated.

## Fixed

### 1. The QR code was not black-on-white — it was theme-coloured

**Severity: high.** This is the one that breaks the widget's whole purpose.

`buildUI` created its `qrcode` elements with `type`, `x`, `y`, `w`, `h` and `data` and no colours.
Per the EdgeTX reference, `lvgl.qrcode` defaults an unset `bgColor` to `COLOR_THEME_SECONDARY3`,
and the common LVGL object settings default an unset `color` to `COLOR_THEME_SECONDARY1`. Both are
theme variables, so the contrast between the QR modules and their quiet zone was whatever the
active theme happened to produce. On a dark theme that can approach dark-on-dark.

The file's own header comment already asserted the correct behaviour —

> The QR code itself always stays black-on-white - scanners need it.

— and the code did not implement it. The documentation was right and the code was wrong.

**Fix:** `color = BLACK, bgColor = WHITE` on both `qrcode` elements. `BgColor`, `TxtColor` and
`SolidBG` continue to apply to the panel rectangle and the labels only, which was the intent.

**Failing observation:** a code that renders and looks plausible on screen while a phone will not
lock onto it. "It displays" is not evidence — only a successful scan is. Task 4.2 scans on both a
dark and a light theme, before and after, which also settles whether this was a repair or
insurance: if the shipped version already scanned on a dark theme, that theme's
`COLOR_THEME_SECONDARY3` simply happens to be light.

### 2. A failed SD write retried on every frame

**Severity: medium.**

`saveFix` stamped `w.lastSave` only inside `if f then`. The rate limit in `poll` is

```lua
if w.needsSave and w.lat and
   (w.lastSave == nil or getTime() - w.lastSave > SAVE_TICKS) then
```

so if `io.open(SAVE_PATH, "w")` returned nothing — no `/LOGS/` folder, no card, card full — then
`lastSave` stayed `nil`, the test stayed true forever, and `needsSave` stayed set. `poll` is called
from `refresh`, which runs once per frame. The widget would attempt an SD card open on every frame
for as long as the card stayed unwritable.

**Fix:** stamp `w.lastSave = getTime()` on the *attempt*, outside the `if f then`. A failed write
now backs off for `SAVE_TICKS` (10 s) exactly like a successful one.

**Deviation from the plan, recorded deliberately.** Task 2.2 also said to clear `w.needsSave`
whether or not the open succeeded. It is left set instead. Clearing it would drop a failed write
entirely and wait for the next coordinate change to try again — and a crashed quad stops moving, so
its coordinates stop changing. The one fix that matters most is exactly the one that would never be
retried. Keeping the flag set gives a retry every 10 s until it succeeds, which still satisfies the
spec requirement ("does not retry the write on every frame").

**Failing observation:** task 4.3 — rename `/LOGS/` on the card, run the widget with a live fix for
a minute, and watch for the radio stuttering.

### 3. Square zones showed a QR code and no status at all

**Severity: medium.**

The portrait branch gated its status line on `showText = (H - W) >= 24`. For a square zone that is
`0 >= 24`, false — so the widget rendered the QR and nothing else. No `LIVE`, no `SAVED`, no age.

That is the single piece of information that distinguishes a fix received thirty seconds ago from
one restored off the SD card after a power cycle. Walking to the first is a search; walking to the
second may be a walk to last weekend's flying field. The coordinates alone cannot tell you which
you have.

**Fix:** room for the status line is reserved *before* the QR is sized, in both branches, so the
QR shrinks to make room rather than the status being dropped.

**Verification:** the arithmetic was walked across ten zone geometries. A 200×200 zone now yields
`size = 166` with the status at y=176 (fits in 200); a 136×136 zone yields `size = 102` with the
status at y=112 (fits in 136). Hardware check is task 4.6.

### 4. The QR dimension had no floor

**Severity: low-medium.**

`size` was derived purely by subtraction — `math.min(H - 2*pad, W - 100)` in the wide branch,
`math.min(W - 2*pad, H - 2*pad - 22)` in the portrait branch — with no lower bound. The EdgeTX
reference requires `w` and `h` to be equal and positive for a valid code.

Walking real zone geometries: a 100×28 zone produces `size = 0`, and a 160×32 zone produces
`size = 20` — a code no phone will resolve. Whether EdgeTX errors or silently renders nothing on a
zero-sized `qrcode` was not established, and did not need to be: neither outcome is acceptable.

**Fix:** `MIN_QR = 56`. Below it the widget renders the coordinates as text instead — still usable,
because a human can type them into a map by hand — rather than handing `lvgl.qrcode` a degenerate
dimension.

## Found and deliberately not fixed

Each of these is real. None was judged worth an edit to a file that is currently flying.

### The save is a truncating write, so a power cut can lose the fix

`saveFix` opens with `"w"`, which truncates before the new coordinates are written. Losing power
inside that window leaves an empty or partial file, and the previously saved fix is gone — in
precisely the scenario the feature exists for.

**Field consequence: real but very unlikely.** The exposure is sub-millisecond against a 10 s write
interval.

**Why not fixed:** the EdgeTX Lua io API has no rename, so an atomic write would mean an
alternating two-file scheme with a validity marker. That is a meaningful rewrite of the persistence
path to close a window three or four orders of magnitude smaller than the interval itself. Worth
revisiting only if a lost fix is ever actually observed.

### `getTime()` restarts at radio boot

Ages are computed as differences against a tick counter that resets on power-on.

**Field consequence: none today.** A fix restored from the card sets `fromFile`, and `statusShort`
returns `SAVED` for that case before it ever computes an age. The reset is unreachable.

**Why it is written down:** it becomes a live bug the moment someone makes restored fixes report an
age — which is a natural-looking improvement. It would then read as a few seconds old regardless of
how long ago it was saved, which is worse than saying nothing.

### `update()` does not stamp `lastBuild`

`update` calls `buildUI` when the user changes an option, but leaves `w.lastBuild` alone, so the
next `refresh` can rebuild again immediately.

**Field consequence: none.** Two LVGL rebuilds while the user is sitting in the widget settings
screen, on the ground.

### The wide-layout text column is ~88 px, not the ~94 px the comment claims

`size` is capped at `W - 100` and the text column starts at `2*pad + size`, leaving `W - 88`… i.e.
88 px, not 94.

**Field consequence: none.** The comment is inaccurate by 6 px; the layout is fine. Left alone so
this file and the change's task list stay in agreement about what was touched.

## Checked and found sound

Recorded so the next reader knows the difference between "not looked at" and "looked at and fine".

**The Lua pattern in `loadSaved` is correct.** `string.match(s, "(-?[%d%.]+),(-?[%d%.]+)")` looks
wrong, because `-` is Lua's lazy quantifier. It is not wrong here. Lua parses a pattern item as a
character class optionally followed by `*`, `+`, `-` or `?`; `-` only means "lazy" when it *follows*
a class. At the start of an item there is nothing for it to quantify, so it is a literal hyphen and
`?` makes it optional. `-?` is an optional minus sign, which is what negative latitudes and
longitudes need.

**`hasFix` correctly rejects null island.** `type(v) == "table" and v.lat ~= nil and v.lon ~= nil
and (v.lat ~= 0 or v.lon ~= 0)`. A GPS with no fix reports zeros, and encoding `0.000000,0.000000`
would send the user to the Gulf of Guinea. This matches the fleet-wide finding that zeros mean a
working receiver without a fix — see `../README.md`.

**`getValue` returning a non-table is handled.** When no sensor named `GPS` exists, `getValue`
returns a number rather than a table. The `type(v) == "table"` guard catches it, so a model without
GPS telemetry shows the waiting state instead of erroring.

**The rate-limit arithmetic is right.** `getTime()` counts 10 ms ticks, so `REBUILD_TICKS = 500` is
5 s and `SAVE_TICKS = 1000` is 10 s, as the comments claim. `statusShort` divides by 100 to get
seconds, also correct.

**First fix appears immediately.** `refresh` rebuilds without waiting for the rate limit when
`w.builtData == nil`, so the transition out of "Waiting for GPS fix..." is not delayed by up to 5 s.

**Polling happens on hidden screens.** `background` calls `poll`, so the position keeps being
captured when the widget is not the active screen. This matters — the fix has to be captured while
you are looking at something else.

## Open — cannot be settled from documentation

**Is a widget's LVGL coordinate origin the zone or the screen?**

The EdgeTX reference documents `x` and `y` as "relative to the top left corner of the parent
object" and does not say what the parent is for a widget script. Its own LVGL widget example
offsets labels by `wgt.zone.x`, which implies the parent is the screen. This widget uses
zone-relative coordinates throughout.

If the parent is the screen, the widget only renders correctly in a full-screen zone — which is
what its README recommends, and probably what has been flown, which would explain why nobody has
noticed.

**Not guessed at, and deliberately not "fixed".** Adding `+ w.zone.x` speculatively would break the
full-screen case if the current behaviour is already right. The test is task 4.5: put the widget in
a half-screen zone with a fix present and look at where the QR lands. A full-screen zone cannot
answer it — the origin is `0, 0` and both readings agree. Until then `README.md` tells you to use a
full-screen zone.

## Not reviewed

The bundled README's radio-configuration advice (telemetry discovery, battery alarms, TX power) was
carried across to `README.md` largely as written. It is procedural, matches EdgeTX's own menus, and
the user has been following it. Its *aircraft*-side advice was a different matter — see "What was
removed from the bundled README" in `README.md`.
