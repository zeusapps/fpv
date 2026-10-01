# Radio

Transmitter-side configuration. Anything here applies to the whole fleet; anything that differs
per aircraft lives in that aircraft's folder and is linked from here rather than repeated. Anything
that differs per **radio** lives in that radio's folder.

## Radios

| Radio | Firmware | Document | Status |
|---|---|---|---|
| HelloRadio V12 MAX | EdgeTX | `v12-max/README.md` | The fleet's radio to date. |
| Oxbot R1 | OXBOT OS | `oxbot-r1/README.md` | On trial from 2026-09-30. Linked to both aircraft; not yet bench-checked or flown. |
| Radiomaster Pocket | — | not written up | |
| DJI RC3 | — | not written up | DJI radios reach these aircraft over SBUS through the air unit — the `*_SBUS_V1.txt` configs — not over ELRS. |

Every radio has to deliver the channels each aircraft's config reads, on the right kind of control.
That rule, and how it is checked, is `../openspec/specs/radio/channel-mapping/spec.md`.

**Most of this file was written for the V12 MAX and needs EdgeTX.** Those sections say so at the
top. What is not marked applies to any ELRS radio.

```
radio/
  README.md               this file — shared material, plus the V12's widget, telemetry, alarms
  v12-max/README.md       V12 switch assignment and ELRS link settings
  oxbot-r1/README.md      R1 switch assignment, settings, bench check
  CODE_REVIEW.md          review of the GPSQR widget source
  WIDGETS/GPSQR/main.lua  the widget itself (V12 / EdgeTX only)
```

## Pairing

Every radio pairs with every receiver through the fleet's **binding phrase**, entered on the radio.
Receiver bind mode — power-cycling the receiver three times and pressing *Bind* on the radio — is
not used. Decided 2026-09-30: a radio holding the phrase links to any receiver with no per-radio
pairing step, and a new radio joins by entering it. Confirmed that day with the Oxbot R1 and both
aircraft, with no change to either receiver.

`WIDGETS/` mirrors the SD card layout. Copy the folder to the card root and the file lands at
`/WIDGETS/GPSQR/main.lua`. Edit it here and copy to the card, not the other way round.

## GPSQR — the "find my drone" widget

> **V12 MAX / EdgeTX only.** The Oxbot R1 has its own *Find Drone* instead — see
> `oxbot-r1/README.md`.

Shows the drone's last known GPS position as a QR code. Scan it with a phone camera and Google
Maps opens with a pin on the drone.

- Keeps the last valid fix after telemetry is lost (crash, failsafe)
- Saves the fix to `/LOGS/gpsqr_last.txt` every 10 s, so it survives a radio power cycle
- Captures the position in the background, on any screen
- Native LVGL QR rendering, no CPU-heavy Lua generation

It is the backup for GPS Rescue. On the Pavo20 the rescue is configured and **has never been
tested** (`../pavo20-pro-ii/FAILSAFE.md`), which is most of why the widget is worth having.

**State, 2026-09-03.** Installed and working on the V12 MAX: it loads, the QR scans with a phone,
the status word shows, and a fix survives a radio power cycle and comes back marked `SAVED`.
Not yet exercised in the field — and "survives a power cycle" is not the same event as "survives a
failsafe", which is telemetry stopping mid-stream rather than a clean shutdown with a fix already
on the card. What is still unverified is listed in `../HANDOFF.md` under *GPSQR widget*.

### Install

1. Copy `WIDGETS/` from this folder to the **root of the radio's SD card**, so the file ends up at
   `/WIDGETS/GPSQR/main.lua`.
2. Make sure `/LOGS/` exists on the card.
3. On the radio: long-press the model screen → *Setup widgets* → pick a zone → select **GPSQR**.
4. It shows "Waiting for GPS fix..." until a telemetry sensor named `GPS` exists. Getting there is
   the next section.

Requires EdgeTX 2.11+ (LVGL Lua API) and a colour screen.

The widget reads the sensor named exactly `GPS`, which is the CRSF default. If you rename it,
change the `SENSOR` constant at the top of `main.lua`.

### Use a full-screen zone for now

**Known limitation, not yet settled.** EdgeTX documents an LVGL object's `x`/`y` as relative to
"the parent object" without saying what a widget script's parent is, and the EdgeTX reference's own
LVGL widget example offsets its labels by `wgt.zone.x` — implying the parent is the screen, not the
widget's zone. This widget uses zone-relative coordinates.

At full screen the two readings are identical, because the zone origin is `0, 0`. In any smaller
zone they are not. Until someone puts the widget in a half-screen zone and looks, use a full-screen
zone. Written up in `../HANDOFF.md` under *GPSQR widget*, and in the Open Questions of
`../openspec/changes/archive/2026-09-03-add-gpsqr-radio-widget/design.md`.

### What the status words mean

| Word | Meaning |
|---|---|
| `LIVE` | a fix arrived in the last 5 s |
| `47s ago` / `3m ago` | time since the last fix was received |
| `SAVED` | restored from the SD card; age unknown, **and possibly from a different model** |

The status is always shown. A QR code on its own does not tell you whether you are looking at a
position from thirty seconds ago or from last weekend.

> **`SAVED` is not necessarily this aircraft's position.** The widget writes to one file,
> `/LOGS/gpsqr_last.txt`, for the whole radio — not one per model. Switch models and it restores
> and displays the *previous* model's last fix, marked `SAVED`, with nothing on screen saying which
> aircraft it came from.
>
> **Trust `LIVE` and an age. Treat `SAVED` as "some aircraft's last position" until you have seen
> a live fix on the model you are flying.** This is a real defect, found 2026-09-03 and not yet
> fixed — the fix is a per-model save path. `CODE_REVIEW.md` has the detail.

> **A displayed position is only as good as the fix behind it, and the widget does not check.**
> It accepts any coordinates that are not exactly `0, 0`. A flight controller whose receiver has
> not acquired can still send a complete, plausible, entirely wrong position — on 2026-09-03 the
> widget showed a point in Mali while the drone sat indoors on a desk. `LIVE` means *a frame
> arrived recently*, not *the drone knows where it is*.
>
> **Confirm the aircraft had a 3D fix before you trust a pin.** If the widget was running while
> the drone had no fix, delete `/LOGS/gpsqr_last.txt` — otherwise that position comes back as
> `SAVED` on the next power-up. Second real defect, found 2026-09-03, not yet fixed;
> `CODE_REVIEW.md` has the mechanism and why the fix is not being guessed at.

### What the position actually is

The widget shows **the last fix the radio received** — the last one transmitted before the link
died. That is not where the quad came to rest. A quad that tumbles from altitude lands some
distance from the point where its telemetry stopped, and the gap grows with height and wind.

**How far off it is has not been measured.** No figure is quoted here because none has been
established. To establish one: land normally, note the widget's coordinates, and pace out the
error. Until then, treat the pin as the start of the search, not the end of it.

On the Pavo20 specifically, the GPS itself is new — reliable only since 2026-09-01, and its first
outdoor cold-start fix is still unconfirmed (`../HANDOFF.md`). A widget cannot show a fix the
aircraft never got.

### Appearance settings

Long-press the widget → widget settings:

- `BgColor` — panel background (default: near-black)
- `TxtColor` — text colour (default: white)
- `SolidBG` — set OFF for a transparent widget sitting on your theme background. The panel exists
  so text stays readable on any theme.

Those three affect the panel and the text only. **The QR code is pinned to black-on-white in the
code and is not themeable** — see `CODE_REVIEW.md` for why that had to be made explicit.

## Getting FC telemetry onto the radio

If you only see `1RSS`, `2RSS`, `RQly`, `RSNR`, `ANT`, `RFMD`, `TPWR`, `TRSS`, `TQly`, `TSNR`,
those are ExpressLRS *link statistics*. The flight controller is not feeding the telemetry stream
yet.

1. Betaflight → **Receiver tab** → enable the **Telemetry** toggle → Save & reboot. (It moved
   there from the Configuration tab in newer Configurator versions. Version-proof alternative in
   the CLI: `feature TELEMETRY` then `save`.)
   **Gotcha:** some Configurator versions silently switch this back off when you save on the Ports
   tab. After finishing all changes, revisit the Receiver tab and confirm it is still on.
2. ELRS Lua script on the radio → `Telem Ratio` must not be `Off`. `Std` is a good default; racing
   packet modes disable telemetry entirely.
3. Radio → *Model settings → Telemetry → Delete all sensors → Discover new sensors*, with the drone
   powered. The list never refreshes by itself.

Step 1 is the aircraft and applies whatever the radio. Steps 2 and 3 are the V12's EdgeTX menus; on
the Oxbot R1, `Telem Ratio` is under Quick Settings → ELRS Lua and there is no sensor-discovery
step described in its manual.

Sensors that should appear:

| Sensor | Meaning |
|---|---|
| `RxBt` | Battery voltage from the FC |
| `Curr` | Current draw |
| `Capa` | Consumed capacity (mAh) |
| `Bat%` | Remaining battery estimate |
| `FM` | Flight mode |
| **`GPS`** | **Coordinates — what the widget reads** |
| `Sats` | Satellite count |
| `Alt` | Altitude |
| `GSpd` | Ground speed |
| `Hdg` | Heading |

Confirmed working on the FireFly25. **On the Pavo20, almost certainly working** — the widget has
displayed a position while bound to that model, which needs the `GPS` sensor in the stream. One
caveat before calling it confirmed: see the `SAVED` warning below, because a restored position from
another model looks the same on screen.

### GPS module configuration

Per aircraft, not per radio. The correct protocol and baud differ between the quads in this fleet
and getting them wrong is how the Pavo20 lost a week.

- **Pavo20 Pro II** — `../pavo20-pro-ii/GPS_SETUP.md`
- **FireFly25** — `../firefly25/README.md`

No values are given here on purpose. See "What was removed from the bundled README" below.

## Battery voltage warning

**LiHV vs LiPo:** LiHV changes the *top* of the range, not the bottom.

| Per cell | LiPo | LiHV |
|---|---|---|
| Full charge | 4.20 V | 4.35 V |
| Nominal | 3.70 V | 3.80 V |
| Warning (under load) | 3.50 V | 3.50 V |
| Land now (under load) | 3.30 V | 3.30 V |
| Damage below | ~3.0 V | ~3.0 V |

So the low-voltage warning threshold is the **same ≈3.5 V/cell** for both chemistries. LiHV just
gives extra capacity at the top. Only charging differs — LiHV needs a charger in HV mode.

### Per-cell reporting

Use per-cell voltage so one threshold works on every model, 1S whoop and 4S cinewhoop alike. This
is an **aircraft-side setting you apply yourself** — in the Betaflight CLI of each drone:

```
set report_cell_voltage = ON
save
```

`RxBt` then reports average cell voltage. **Confirming observation:** on a freshly charged 4S pack
`RxBt` should read about 3.8 V, not about 15.4 V. If it still reads pack voltage, the setting did
not take.

On a 1S drone pack voltage already equals cell voltage, so the alarm works there without this step.

> No committed `.txt` config in this repo was changed for this. Applying it means editing the
> aircraft's config and re-verifying it — see the aircraft folder.

### The alarm itself

> **V12 MAX / EdgeTX only.** Whether the Oxbot R1 can alarm on `RxBt` at all is not yet known —
> `oxbot-r1/README.md`, *What is not verified*. The thresholds above apply to any radio that can.

Logical switches are per-model, so repeat this for each model on the radio.

1. *Model settings → Logical Switches* → `L01`:
   - Function `a < x`, V1 `RxBt`, V2 `3.5`
   - Duration/Delay `2.0 s` — stops punch-outs triggering it on voltage sag
2. *Model settings → Special Functions* → `SF1`:
   - Trigger `L01`, action `Play Track` → `batlow` (or `Vibrate`, or `Play Value → RxBt` to hear
     the actual voltage), Repeat `5 s`

Without per-cell reporting the threshold is 3.5 V × cell count: 1S = 3.5 V, 3S = 10.5 V,
4S = 14.0 V.

### Why the same 3.5 V behaves differently per aircraft

The discharge curve falls off a cliff below ~3.5 V/cell, and what the radio shows is voltage
**under load**, which sags differently on each airframe.

- A **1S whoop** (Meteor75) sags heavily — 3.5 V in flight often means ~3.7 V resting, plenty
  left. Whoops are commonly flown to 3.1–3.3 V under load.
- The **FireFly25** draws high current for its pack and is heavier, so 3.5 V in cruise is close to
  its true resting voltage. The tank really is nearly empty and it collapses fast from there.
- On a **multi-cell pack**, per-cell is an average. One weak or aged cell can sit far below the
  others and cause a sudden collapse. If one pack consistently dies early, check its balance on the
  charger.
- Cold weather increases sag — expect the cliff earlier in winter.

Suggested per-model thresholds: Meteor75 (1S) keep 3.5 V; FireFly25 warn at **3.6 V** ("head
home") and treat 3.5 V as "land now".

### mAh alarm — the gauge that doesn't sag

Consumed capacity is a more honest fuel gauge than voltage.

Step 1 is the aircraft; steps 2 and 3 are V12 / EdgeTX.

1. Betaflight → Power tab: set the pack's rated capacity so `Capa` and `Bat%` mean something.
2. Radio → Logical Switch `L03`: `a > x`, V1 `Capa`, V2 ≈ 75–80 % of the pack (e.g. `600` for a
   750 mAh pack).
3. Special Function: `L03` → Play Track / Vibrate.

Use mAh as the primary "time to land" signal and voltage as the secondary "land NOW" alarm.

## Return-to-home

Per aircraft. GPS Rescue values depend on the airframe's thrust margin, endurance and wind
penetration — a cinewhoop and a 2.5" freestyle quad do not get the same numbers, and this repo has
the tested procedure in one place.

- **Pavo20 Pro II** — `../pavo20-pro-ii/FAILSAFE.md`, including the fact that it is **configured
  but untested**, and the switch-testing procedure that must happen before it is trusted.

Nothing about rescue configuration belongs here. See below.

## Transmitter power and link warnings

> **The power and `L02` steps are V12 MAX / EdgeTX.** The Oxbot R1 has fixed power levels and no
> Dynamic setting in its manual — `oxbot-r1/README.md`, *Settings*. The diagnosis under *A switch
> shows on the radio but not in Betaflight* is Betaflight-side and applies to any radio, apart from
> its steps 2–3, which name EdgeTX screens.

- `TPWR` shows current transmit power in mW. Put it on a widget if you want it visible.
- Configure power in the **ExpressLRS Lua script**: set `Max Power` and turn `Dynamic` **ON**.
  Dynamic power idles low (10–25 mW) and ramps up when link quality drops — better for battery,
  heat and range at once.
- The V12 MAX's internal module goes to 1000 mW. For a small quad at normal distances,
  `Max Power 250 mW + Dynamic` is plenty. Go higher only for genuine long range.
- **Early warning, so you turn back before failsafe:** Logical switch `L02`: `a < x`, V1 `RQly`,
  V2 `40`, duration `1.0 s` → Special Function: Play Track "signal low" / vibrate. `RQly` is uplink
  link quality in percent; healthy is 70–100.

### A switch shows on the radio but not in Betaflight

**First, know what the symptom cannot be.** On CRSF the flight controller always presents
**16 channels**, whatever the radio actually sends — `CRSF_MAX_CHANNEL` is `16`
(`src/main/rx/crsf.h:28`) and `crsfRxInit` assigns it unconditionally to
`rxRuntimeState->channelCount` (`src/main/rx/crsf.c:629`). `MSP_RC` then reports that many values
(`src/main/msp/msp.c:1317-1321`). So the Receiver tab draws sixteen bars on an ELRS quad even if
the radio transmits eight. **"AUX 6 is missing" is not a possible symptom; "AUX 6 does not move"
is.**

A channel that never arrives reads **exactly 1500**, not zero and not noise. `rxInit` presets every
`rcData[i]` to `midrc` (`src/main/rx/rx.c:307-309`) and `readRxChannelsApplyRanges` only writes
indices below `rxChannelCount`, so an unfed channel keeps its preset forever. A bar parked dead
centre while you work the switch is the signature.

Check in this order. The first two need no quad.

1. **Naming.** Betaflight calls CH10 "AUX 6" (CH5 = AUX 1, CH6 = AUX 2 … CH10 = AUX 6). Watch the
   AUX 6 bar on the Receiver tab; select AUX 6 on the Modes tab.
2. **The radio's own channel monitor.** If CH10 does not move here, nothing downstream matters —
   it is a mixer problem, not a link problem. Momentary buttons are the usual culprit: they output
   only while held unless a sticky logical switch latches them.
3. **Radio channel range.** *Model setup → Internal RF → Channel range* must cover the channel
   (CH1–16 is the default). The channel monitor shows mixer output *before* this limit, so a
   channel can move on the radio and never be transmitted.
4. **ELRS switch mode — only matters on "Full" packet rates.** `Hybrid` and `Wide` both carry to
   CH12 and are the only modes available from 50Hz through F1000Hz, so on those rates this cannot
   be the cause. The Full-Res modes exist *solely* on `100Hz Full` and `333Hz Full`, and one of
   them truncates: **`8ch` stops at CH9.** This is what bit the Pavo20 — see the table below.
5. **`max_aux_channels`** — note the plural in the CLI, though the struct field is singular.
   `rxChannelCount = MIN(max_aux_channel + NON_AUX_CHANNEL_COUNT, channelCount)`
   (`src/main/rx/rx.c:402`) caps what gets processed into `rcData`. The default is
   `DEFAULT_AUX_CHANNEL_COUNT`, which is `MAX_AUX_CHANNEL_COUNT` (14) on an FPU MCU and 6 without
   (`src/main/target/common_post.h:46-50`). **Both defaults leave CH10 alive** — 14 gives channels
   1–18 clamped to 16, and even 6 gives 1–10. So this only bites if somebody set it by hand. One
   `get max_aux_channel` settles it.

**Round-robin is not a fault.** In `Hybrid` and `Wide` only AUX 1 rides every packet; AUX 2–8 take
turns. AUX 6 therefore updates at roughly a seventh of the packet rate and, in `Hybrid`, at 3-bit
resolution. A coarse, visibly laggy AUX 6 bar is the mode working as designed — and it means a
button pressed for only a few tens of milliseconds can fall between slots.

### What each Full-Res switch mode actually transmits

Read off the ExpressLRS source at **tag 3.5.6** — the version on this fleet's receivers —
`src/lib/OTA/OTA.cpp`, `GenerateChannelData8ch12ch` and `UnpackChannelData8ch`. Do not take this
from the docs page: it describes the v4.0 layout, which is different (see the caveat below). Each
full-res packet carries two groups of four 10-bit channels, and the group offsets are what decide
everything:

| Mode | Every packet | Half rate (alternating) | Never sent |
|---|---|---|---|
| `8ch` | CH1–4, CH5 *(2-position)*, CH6–9 | — | **CH10–16** |
| `12ch Mixed` | CH1–4, CH5 *(2-position)* | CH6–9 / CH10–13 | CH14–16 |
| `16ch Rate/2` | — | CH1–8 / CH9–16 | — |

**CH5 is special, but only in `8ch` and `12ch Mixed`.** In those two modes the transmitter sends it
as a single bit — `ota8->rc.ch4 = CRSF_to_BIT(channelData[4])`, per the comment "All channel data
is 10 bit apart from AUX1 which is 1 bit" — and the receiver restores it with
`channelData[4] = BIT_to_CRSF(ota8->rc.ch4)`. That line sits in the **`else` branch** of
`UnpackChannelData8ch`, so in `16ch Rate/2` it never runs: the transmitter still sets the bit, the
receiver ignores it, and CH5 arrives as ordinary 10-bit data in the CH1–8 group instead.

The practical consequences:

- **In `8ch` and `12ch Mixed`, CH5 can only ever be a 2-position switch** — a 3-position or
  analogue source on CH5 collapses to two states. It rides every packet, which is why ARM lives
  there.
- **In `16ch Rate/2`, CH5 regains full resolution but drops to half rate** along with everything
  else, sticks included. Nothing is lost that matters at 333Hz Full, but be clear that the arm
  channel is no longer the every-packet channel it is in the other two modes.
- **`12ch Mixed` is the only mode that keeps CH1–4 at the full packet rate.** If you need CH10–13
  and want maximum stick rate, that is the one to pick.

**This mapping is version-specific and will expire.** At ExpressLRS `master` (v4.0) the offsets
differ — `8ch` becomes CH1–8, `12ch` tops out at CH12, and the arm bit moves to a dedicated
`isArmed` field mirrored into CH14/AUX10. Re-read `OTA.cpp` at the tag you are actually running
before trusting any of the above.

## Field workflow

> Written for the V12 MAX: `SD Logs` and the GPSQR widget are EdgeTX. On the Oxbot R1, steps 1–3
> below use Quick Settings → *Find Drone* instead, and checking `Sats` before trusting its pin
> matters until it has been shown to refuse a no-fix position (`oxbot-r1/README.md`).

Worth enabling:

- Special Function: `SD Logs` on the arm switch, 1 s interval — a full CSV flight log including
  GPS in `/LOGS/`. The ultimate fallback.
- Beeper on a switch. It also sounds automatically on failsafe.
- Check `Sats` before arming.

When a drone goes down:

1. Open the GPSQR widget screen.
2. Scan the QR with your phone → Google Maps opens on the pin → *Directions* → walk.
3. As you get close the link often reconnects, and the widget flips from an age to `LIVE` and
   updates the pin.
4. Hit the beeper switch and follow the sound.

Never power the radio off after losing a drone — though the widget saves the fix to
`/LOGS/gpsqr_last.txt` anyway.

## What was removed from the bundled README

The widget shipped with a README that doubled as a full setup guide. Two of its sections were
aircraft configuration rather than radio configuration, and both were wrong for at least one
aircraft in this fleet. They are recorded here rather than deleted silently, in the same spirit as
the disproven hypotheses kept in `../pavo20-pro-ii/GPS_SETUP.md`.

**§3, "GPS module configuration".** It said:

> Configuration tab: **GPS enabled**, protocol **UBLOX** (auto-baud on modern firmware). Save.

Correct for the FireFly25 it was written against, and **not safe to apply blind to any other
aircraft**. Two reasons, neither of which depends on what any particular aircraft runs today:

- **The auto-baud half does nothing.** At Betaflight 2025.12.2, `gps_auto_baud` is settable from
  the CLI but is never read by `io/gps.c`. An instruction to turn it on cannot have the effect it
  claims, on any aircraft in this fleet.
- **The protocol is a per-aircraft fact.** It depends on the module, the wiring and what has
  actually been observed on that airframe — none of which a radio-side document can know. Each
  aircraft folder states its own, with the firmware version it was read at.

This entry originally gave a third reason, specific to the Pavo20 Pro II, asserting that its
module could not complete UBLOX detection. **That was disproven on 2026-09-03** and has been
removed; the mistake is recorded in `../pavo20-pro-ii/GPS_SETUP.md`. It is a good illustration of
why this rule exists: the aircraft-side value changed, and because it had been copied into
`radio/`, the copy here went silently wrong. **For any aircraft's GPS protocol and baud, go to that
aircraft's folder** — for the Pavo20, `../pavo20-pro-ii/GPS_SETUP.md`.

**§5, "GPS Rescue".** It gave a complete rescue setup — "*Minimum satellites: 8*", "*Return
altitude: 40 m fixed is a sane default*" — against "Betaflight 4.4/4.5". The fleet runs 2025.12.2,
and the Pavo20's actual configured return altitude is 25 m, not 40 m, because a ducted cinewhoop
carrying an O4 Pro climbs slowly and has 8–10 minutes of endurance. Two contradictory rescue
procedures in one repo is how someone ends up flying the wrong one. `../pavo20-pro-ii/FAILSAFE.md`
is the single source, and it is honest about the fact that none of it has been tested in the air.

The rule this follows is written down as a requirement, so it does not erode:
`../openspec/specs/radio/gpsqr-widget/spec.md` — "Radio-side
documentation SHALL NOT restate per-aircraft flight controller settings".
