# Radio — HelloRadio V12 MAX

Transmitter-side configuration. One radio flies all three aircraft, so anything here applies to
the fleet; anything that differs per aircraft lives in that aircraft's folder and is linked from
here rather than repeated.

```
radio/
  README.md               this file — widget install, telemetry, alarms, TX power
  CODE_REVIEW.md          review of the GPSQR widget source
  WIDGETS/GPSQR/main.lua  the widget itself
```

`WIDGETS/` mirrors the SD card layout. Copy the folder to the card root and the file lands at
`/WIDGETS/GPSQR/main.lua`. Edit it here and copy to the card, not the other way round.

## GPSQR — the "find my drone" widget

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
on the card. What is still unverified is listed in `../HANDOFF.md` item 5.

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
zone. Written up in `../HANDOFF.md` item 5, and in the Open Questions of
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

Check in this order:

1. **Naming.** Betaflight calls CH10 "AUX 6" (CH5 = AUX 1, CH6 = AUX 2 … CH10 = AUX 6). Watch the
   AUX 6 bar on the Receiver tab; select AUX 6 on the Modes tab.
2. **Radio channel range.** *Model setup → Internal RF → Channel range* must cover the channel
   (CH1–16 is the default). The radio's channel monitor shows mixer output *before* this limit, so
   a channel can move on the radio and never be transmitted.
3. **ELRS packet mode.** Standard modes carry 12 channels (4 + 8 aux), but Full-Res "8ch" modes
   carry only CH1–8. Check Packet Rate in the ELRS Lua script; avoid "8ch" modes if you use CH9+.

## Field workflow

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

Correct for the FireFly25 it was written against. **Wrong for the Pavo20 Pro II**, which is the
aircraft the radio is most often bound to and the one where the widget matters most. Its BZ-181
(u-blox M10) never answers a UBX `MON-VER`, so the UBLOX driver cannot leave `DETECT_BAUD`
(`gps.c`, read at Betaflight 2025.12.2). That aircraft runs the **NMEA** provider at a fixed
115200 with `gps_auto_baud` and `gps_auto_config` off. Following the removed advice breaks a GPS
that currently works. Full write-up: `../pavo20-pro-ii/GPS_SETUP.md`.

**§5, "GPS Rescue".** It gave a complete rescue setup — "*Minimum satellites: 8*", "*Return
altitude: 40 m fixed is a sane default*" — against "Betaflight 4.4/4.5". The fleet runs 2025.12.2,
and the Pavo20's actual configured return altitude is 25 m, not 40 m, because a ducted cinewhoop
carrying an O4 Pro climbs slowly and has 8–10 minutes of endurance. Two contradictory rescue
procedures in one repo is how someone ends up flying the wrong one. `../pavo20-pro-ii/FAILSAFE.md`
is the single source, and it is honest about the fact that none of it has been tested in the air.

The rule this follows is written down as a requirement, so it does not erode:
`../openspec/specs/radio/gpsqr-widget/spec.md` — "Radio-side
documentation SHALL NOT restate per-aircraft flight controller settings".
