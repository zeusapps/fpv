# Failsafe — Pavo20 Pro II

Configured procedure: **GPS Rescue — live.** `get failsafe_procedure` returned `GPS-RESCUE` on
2026-10-02. **It is an accepted risk, not a qualified configuration**: the pilot armed it after one
switch-triggered return on 2026-10-01, which oscillated in altitude and was taken over before it
landed, and kept it after being told what is unproven. Nobody has seen this rescue land, and no
attempt has been logged. If a logged rescue disarms in the air, flies away or does not descend,
revert — see *If you decide against it* at the end.

| File | What it does | When |
|---|---|---|
| `PAVO20PRO2_GPS_RESCUE_TUNING.txt` | The rescue parameters. Changes nothing about failsafe. | **Now.** Paste it before testing. |
| `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt` | One line: `failsafe_procedure = GPS-RESCUE`. | Written as "only after the switch test passes". **Applied before it had** — see the file header for which gates were unmet. |

The split exists because the two halves carry completely different risk. The tuning block only
changes what a rescue you deliberately trigger does, and it makes it gentler than the firmware
defaults — there is no reason to delay it and a good reason not to, below. The one-line block
changes what happens when the link dies, and that is the part that must be earned.

**On signal loss the aircraft now tries to fly home.** It climbs to the highest altitude of this
power-up plus 10 m, returns, and descends toward where the pack was first armed. Before block 2 it
sat at the 2025.12.2 default of `DROP_IT` (`src/main/flight/failsafe.c:78`) and fell.

*Superseded 2026-10-02, kept because the reasoning still holds:* **"The failsafe stays on DROP until
a rescue has actually been flown home, more than once."**
Configuring the rescue is not qualifying it. `DROP` fails by cutting motors, so the aircraft falls
where it already was; GPS Rescue fails by flying under power in a direction nobody chose. A rescue
that has not been flown is not the safer option, it is the untested one — and the first attempt on
this aircraft, 2026-09-03, ended with the motors stopped and the quad on the ground.

**Paste block 1 before you switch-test.** A rescue on an unconfigured board runs firmware defaults,
and the default `ascend_rate` is `750` cm/s — a 7.5 m/s climb demand on an airframe with almost no
thrust margin. It will simply go to full throttle. The default `ground_speed` is likewise 7.5 m/s
against the 5 m/s chosen here. Testing on those numbers tests the wrong aircraft.

## Read this first

GPS Rescue is the only failsafe procedure that keeps the motors running and flies the aircraft
under its own power. Every other option makes the quad fall or land where it is.

That means a **misconfigured GPS Rescue is worse than no rescue**. Instead of dropping, the quad
flies — possibly in the wrong direction, possibly into something, possibly toward people. The
failure mode of `DROP` is a broken quad. The failure mode of a bad rescue is a flyaway.

So it must be tested on a switch before it is trusted as a failsafe. Not "should" — must.

## Why this airframe is a hard case

Stated plainly so the limits are understood rather than discovered:

- **Little thrust margin.** A 2.2" ducted quad carrying an O4 Pro is heavy for its disc area. It
  climbs slowly and cannot fight much wind.
- **Poor penetration.** Ducts trade efficiency in forward flight for thrust in hover. `500` cm/s
  ground speed is set low deliberately; raising it will not help it beat wind, it will just drain
  the pack faster.
- **Short endurance.** 8–10 minutes total. A rescue from any distance eats a meaningful fraction.
- **The GPS is new and unproven in flight.** It was only made to work reliably on 2026-09-01, and
  the first cold-start fix had not yet been achieved outdoors.

None of that makes GPS Rescue wrong — it makes testing it non-optional.

## Prerequisites

Work down this list. Do not skip ahead.

1. **GPS is reliably acquiring a fix outdoors.** Configurator GPS tab shows a satellite count and a
   3D fix within a few minutes, repeatably, across several flights.
2. **Home is being set.** OSD home distance and direction behave correctly — walk away from the
   takeoff point with the quad disarmed and confirm the distance climbs.
3. **`gps_rescue_min_sats = 8` is being met comfortably** in the places you fly, not just barely.
4. **The quad hovers at a stable throttle** and the tune is settled. Rescue relies on predictable
   thrust response.

Note `gps_set_home_point_once = ON` on this quad: home is set on the first fix and **kept across
arms**. If you fly several packs from different spots in one session, home stays at the first one.
Power cycle between locations, or set it to `OFF`.

## Assigning GPS Rescue to a switch

CH10 / **AUX 6** is the intended control, and is free — the existing `aux` lines use AUX 1–AUX 5
only. Channel numbers in `aux` are 0-indexed, so AUX 6 is channel `5`, and the permanent box ID for
GPS Rescue is **46** (`src/main/msp/msp_box.c:95`, `{ .boxId = BOXGPSRESCUE, .boxName = "GPS
RESCUE", .permanentId = 46 }`). Slot 6 is the next free `aux` index:

```
aux 6 46 5 1700 2100 0 0
save
```

Set it from the Modes tab instead if you prefer; this is the same thing written out. Confirm on the
**Receiver** tab that AUX 6 actually reaches 1700+ when the switch is on before you rely on the
range — do not assume the throw.

**If "GPS Rescue" does not appear in the Modes tab at all**, it is gated on the feature, not on a
fix: `msp_box.c:248-253` offers the box only when `USE_GPS` and `USE_GPS_RESCUE` are compiled in,
`FEATURE_GPS` is enabled, `FEATURE_3D` is not, and the craft is not fixed wing. This aircraft has
`feature GPS`, so it should be there.

The control is a **2-position switch** on the V12 MAX, latching — so it holds the rescue on
without you keeping a finger on it, and one flick cancels. That is the right shape for both the
testing below and for real use.

**AUX 6 was dead until 2026-09-03 and the cause was on the radio, not here.** The link ran ELRS
`333Hz Full` with Switch Mode `8ch`, which transmits nothing above CH9 — CH10 never left the
transmitter. Switch Mode is now `12ch Mixed` and AUX 6 is confirmed moving. If it ever goes dead
again, the ladder is in `../radio/README.md` under *A switch shows on the radio but not in
Betaflight*, and the per-mode channel map is in the section below it. Note that on CRSF the AUX 6
bar always *exists* and reads exactly 1500 when nothing feeds it, so "the bar is there" proves
nothing — watch the number.

**A momentary button would be the wrong control here**, for the record: GPS Rescue is active only
while the channel sits inside the configured range, so a momentary would cancel the rescue the
moment you released it. If you ever move RTH to a button, latch it with a sticky logical switch in
EdgeTX.

## Where you can and cannot trigger a rescue

Tested in the field 2026-09-03: triggered close in and low, and **the quad disarmed instantly and
dropped**. That is correct, designed behaviour, not a fault. The three distance bands, all from
`gps_rescue_multirotor.c:717-742`:

| Distance from home | Altitude | What happens |
|---|---|---|
| **< 5 m** | **< 4 m** | `RESCUE_ABORT` → **immediate disarm.** The quad falls. |
| < 5 m | ≥ 4 m | Treated as the band below |
| **< 15 m** (`min_start_dist`) | any | Climbs to at least 10 m and **pitches forward, flying *away* from you** until past 15 m, then returns. Descent distance halves to 7.5 m. |
| **> 15 m** | any | Normal rescue: climb → rotate → fly home → descend → land |

The 4 m figure is `isBelowLandingAltitude()`, `getAltitudeCm() < 100 * landingAltitudeM`
(`autopilot_multirotor.c:386-389`), and `ap_landing_altitude_m` defaults to `4`
(`pg/autopilot_multirotor.c:36`). The 5 m and 15 m figures are the literal `5.0f` at line 725 and
`gps_rescue_min_start_dist` respectively.

`RESCUE_ABORT` calls `disarm()` **and** `setArmingDisabled(ARMING_DISABLED_ARM_SWITCH)`
(line 834-838), so re-arming needs the arm switch cycled off and on.

**What the drop actually proved, which is more than it looks:**

- The switch reaches Betaflight and the rescue state machine ran. AUX 6 → `BOXGPSRESCUE` works.
- **Home was set.** With no home point the code takes the `RESCUE_NO_HOME_POINT` branch, which
  under `FS_ONLY` hovers for 20 s rather than disarming — "float around if switch induced"
  (line 723). A disarm means `STATE(GPS_FIX_HOME)` was true.
- GPS had a fix with at least 8 satellites, because `gps_rescue_allow_arming_without_fix = OFF`
  and `min_sats = 8` mean the quad could not have armed otherwise (`fc/core.c:400-407`).

So the first field session cleared prerequisites 1 and 2 by accident. **Trigger the next test from
beyond 15 m** — 25–30 m is the sensible number — or you will keep landing in one of the two
short-range branches and never see a real rescue.

## Testing on a switch — do this before trusting failsafe

1. Assign **GPS Rescue** to AUX 6 as above and confirm it on the Receiver tab.
2. **Paste `PAVO20PRO2_GPS_RESCUE_TUNING.txt`** and `save`. Do not test on firmware defaults —
   see the note at the top of this file. Leave block 2 alone.
3. **Measure the hover throttle and correct `ap_hover_throttle`.** The committed `1420` is the
   pilot's OSD reading of about 42% on 2026-10-01, on a **4S 850 mAh** pack. It replaced `1340`,
   which was derived from `thr_hover = 34` and under which the 2026-10-01 rescue hopped in altitude.
   The figure is only right for the pack it was read on, so re-read it on the pack you test with. Hover the aircraft steadily, read the **throttle percentage
   from the OSD** (`osd_throttle_pos` is configured on this aircraft), and convert:
   `value = percent x 10 + 1000` — 34% is `1340`, 38% is `1380`. Set it and confirm with
   `get ap_hover_throttle`. **If the measurement disagrees with 1420, the measurement wins.** This
   is the setting most likely to have caused the 2026-09-03 drop; see *Settings reference* below.
4. **Arm the logging.** In the CLI: `set debug_mode = RTH`, `save`. There is **no
   `feature BLACKBOX`** at 2025.12.2 — the CLI rejects the name outright
   (`###ERROR IN feature: INVALID NAME: BLACKBOX###`, confirmed on this aircraft 2026-09-20).
   Logging is on whenever `blackbox_device` is not `NONE`, and it already reads `SPIFLASH`;
   confirm with `get blackbox_device`.

   **Erase the flash before every attempt** — `flash_erase` in the CLI, or the Configurator
   **Blackbox** tab, *Erase Flash*. This is not housekeeping. A full flash records nothing, warns
   nobody, and you land believing you have a log — which is precisely what cost the 2026-09-03
   attempt. Check with `flash_info`: `usedSize` must be well below `totalSize` (16777216 on this
   board, 16 MB) before you fly.

   To pull logs off, `msc` reboots the board as a USB mass-storage device and the logs appear as
   files; power cycle to come back. Faster than the Configurator download.

   `debug_mode` was `GYRO_FILTERED`; restore it when testing is finished.
5. Pick a **large open field**. No trees, no people, no roads. Somewhere a flyaway is survivable
   and recoverable on foot.
6. Take off, get a solid fix, fly out to **40–60 m** and up to a comfortable altitude.
7. **Flip the switch.** Keep your thumbs on the sticks.
8. Watch what it does. It should climb, turn toward home, fly back and begin descending.
9. **Flip the switch off the instant anything looks wrong** and fly it home manually.
10. **Download the log and read it before flying again.** With `debug_mode = RTH` the rescue
    records its own state: slot 0 is max altitude in decimetres, **slot 2 is
    `failure * 10 + phase`**, and slot 3 is `secondsFailing * 100 + secondsLowSats`
    (`gps_rescue_multirotor.c:850`, `:474-475`). Slot 2 is the one that matters — it says which
    phase was active and which failure was set at the moment the aircraft came down, which is
    exactly what the 2026-09-03 attempt could not tell us.

Repeat at a few distances and directions before trusting it. If it consistently returns and
descends near you, the configuration is sound.

**An attempt flown without logging does not count**, in either direction. It cannot accept the
configuration and it cannot condemn it — repeat it with the log running.

If it wanders, oscillates, fails to climb, or heads the wrong way — turn the switch off, land, and
set `failsafe_procedure = DROP` until it is understood. Do not fly with a rescue that behaved
oddly on the bench-test.

**Exception, recorded 2026-10-02:** the 2026-10-01 rescue oscillated, and the pilot kept
`GPS-RESCUE` anyway, judging a rescue that limps home better than a certain drop. The oscillation is
attributed, unconfirmed, to `ap_hover_throttle` sitting 80 below hover; it is now `1420`. The next
switch test must be logged and allowed to land unaided. If it still oscillates, this paragraph's
rule applies without exception.

## Verifying failsafe itself

Separately from the rescue behaviour, confirm failsafe actually triggers. **Props off**, quad on
the bench, battery connected:

1. Arm, then switch the radio off.
2. Betaflight should enter failsafe. `status` will show the arming disable flags change and the OSD
   will display the failsafe warning.
3. Turn the radio back on and confirm recovery.

Then check the real thing at low altitude over grass, in a wide open space, before flying anywhere
that matters.

## Settings reference

| Setting | Value | Why |
|---|---|---|
| `failsafe_procedure` | `GPS-RESCUE` | Return home rather than drop. **Hyphen** — the underscore form is rejected |
| `gps_rescue_allow_arming_without_fix` | `OFF` | No fix, no arm — prevents a rescue with no home |
| `gps_rescue_min_sats` | `8` | Rescue requires a genuinely good fix |
| `gps_rescue_min_start_dist` | `15` m | Closer than this, descend instead of returning |
| `gps_rescue_initial_climb` | `10` m | Get above obstacles before turning |
| `gps_rescue_alt_mode` | `MAX_ALT` | Return at the highest altitude reached this flight |
| `gps_rescue_return_alt` | `25` m | **Inert under `MAX_ALT`** — see below |
| `gps_rescue_sanity_checks` | `RESCUE_SANITY_FS_ONLY` | Safer than `ON` for switch testing — see below |
| `gps_rescue_ascend_rate` | `200` cm/s | 2 m/s — modest, this airframe is heavy |
| `gps_rescue_descend_rate` | `100` cm/s | 1 m/s |
| `gps_rescue_ground_speed` | `500` cm/s | 5 m/s — controllable, not ambitious |
| `gps_rescue_descent_dist` | `15` m | Start descending 15 m out |
| `ap_hover_throttle` | `1420` | Measured 2026-10-01 off the OSD, ~42% on a 4S 850 mAh pack; was `1340`, derived from `thr_hover`. The throttle commanded at rescue onset; the `1275` default is below this airframe's hover and makes a rescue sink. Re-read on the test pack — step 3 above |
| `debug_mode` | `RTH` | So an attempt produces evidence. Was `GYRO_FILTERED` |

Both lookups were read off the aircraft on 2026-09-03 and both already held the right value;
both equal the 2025.12.2 firmware default and are pinned in the config anyway so the choice is
visible.

### `gps_rescue_return_alt` does nothing under `MAX_ALT`

`returnAltitudeM` is read in exactly one place — the `GPS_RESCUE_ALT_MODE_FIXED` branch
(`src/main/flight/gps_rescue_multirotor.c:179-181`). Under `MAX_ALT` the return altitude is
computed instead as `maxAltitudeCm + initialClimbCm` (line 186-189): **the highest altitude reached
this flight, plus the 10 m initial climb.** The `25` in the config is kept only so that flipping to
`FIXED_ALT` lands on a sane number instead of the firmware's 30 m. Do not read it as the altitude
this quad returns at, and do not tune it expecting an effect.

**This compounds with `gps_set_home_point_once = ON`.** `setReturnAltitude` holds `maxAltitudeCm`
at zero while disarmed *only* when that option is off — "if set_home_point_once is true, hold
maxAlt until power cycled" (line 160-163). So the max altitude carries across arms exactly the way
home position does. Fly one pack to 60 m, land, take off again for a low cruise, trigger a rescue,
and it will climb to 70 m. On an airframe with 8–10 minutes of endurance that is worth knowing.
Power cycling between packs resets both.

### Sanity checks: `FS_ONLY` is the safer choice here, not the weaker one

An earlier version of this document said to keep sanity checks **on**. That was wrong for the
switch-testing this document requires. From `gps_rescue_multirotor.c:366-375`:

- **`RESCUE_SANITY_ON`** — any sanity failure sets `RESCUE_ABORT`, and `RESCUE_ABORT` calls
  `disarm(DISARM_REASON_FAILSAFE)` (line 834-838). During a switch-induced test, that drops the
  quad out of the sky.
- **`RESCUE_SANITY_FS_ONLY`** — aborts only on hard Rx loss (`!isRxReceivingSignal()`). Otherwise
  it sets `RESCUE_DO_NOTHING`: 20 s of level hover with impact-disarm, described in the source at
  line 214 as "20s of hover for switch induced sanity failures to allow time to recover".

**During a real failsafe the two are identical**, because a real failsafe *is* hard Rx loss — both
abort and disarm. The only case where they differ is a switch-induced rescue, and there `FS_ONLY`
hands the aircraft back to you instead of dropping it. The protection the old wording was reaching
for is fully present in `FS_ONLY`.

**`FS_ONLY` does not make a switch test non-destructive, and must not be described as if it did.**
There is a second failure path that **ignores the sanity mode entirely**
(`gps_rescue_multirotor.c:434-460`, under the comment "These conditions ignore sanity mode settings,
and apply in all rescues, to handle getting stuck in a climb or descend"). In `RESCUE_ATTAIN_ALT`,
if the achieved altitude change is under half the target change, a counter increments once per
second; at ten it forces `RESCUE_LANDING`, which enables impact detection and then aborts —
disarming — after a further ten. A quad that cannot climb is brought down by the rescue itself, on
either sanity setting.

So `FS_ONLY` narrows which failures are recoverable. It does not guarantee that flipping the switch
is safe, and a switch-induced rescue **can** disarm the aircraft.

## If you decide against it

`DROP` is the honest default for a cinewhoop flown close in, and there is no shame in it. Block 2
**is** pasted (read back 2026-10-02), so deciding against GPS Rescue now means reverting it.
Confirm with `get failsafe_procedure` that it returns `DROP` afterwards:

```
set failsafe_procedure = DROP
save
```

Block 1 can stay pasted either way. It only affects a rescue you trigger by switch, which remains a
useful thing to have on AUX 6 even if you never make it the failsafe response: it is a
"bring it back to me" button for when you lose orientation, not only a failsafe.

The GPS still earns its place — home distance and direction in the OSD, and position telemetry to
the radio for finding the quad after it lands. That is most of the practical value, without the
flyaway risk.
