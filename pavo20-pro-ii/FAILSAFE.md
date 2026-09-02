# Failsafe — Pavo20 Pro II

Configured procedure: **GPS Rescue**. Settings in `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt`.

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

## Testing on a switch — do this before trusting failsafe

1. Assign **GPS Rescue** to a spare switch in the Configurator **Modes** tab.
2. Pick a **large open field**. No trees, no people, no roads. Somewhere a flyaway is survivable
   and recoverable on foot.
3. Take off, get a solid fix, fly out to **40–60 m** and up to a comfortable altitude.
4. **Flip the switch.** Keep your thumbs on the sticks.
5. Watch what it does. It should climb, turn toward home, fly back and begin descending.
6. **Flip the switch off the instant anything looks wrong** and fly it home manually.

Repeat at a few distances and directions before trusting it. If it consistently returns and
descends near you, the configuration is sound.

If it wanders, oscillates, fails to climb, or heads the wrong way — turn the switch off, land, and
set `failsafe_procedure = DROP` until it is understood. Do not fly with a rescue that behaved
oddly on the bench-test.

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
| `failsafe_procedure` | `GPS_RESCUE` | Return home rather than drop |
| `gps_rescue_allow_arming_without_fix` | `OFF` | No fix, no arm — prevents a rescue with no home |
| `gps_rescue_min_sats` | `8` | Rescue requires a genuinely good fix |
| `gps_rescue_min_start_dist` | `15` m | Closer than this, descend instead of returning |
| `gps_rescue_initial_climb` | `10` m | Get above obstacles before turning |
| `gps_rescue_return_alt` | `25` m | Return altitude |
| `gps_rescue_ascend_rate` | `200` cm/s | 2 m/s — modest, this airframe is heavy |
| `gps_rescue_descend_rate` | `100` cm/s | 1 m/s |
| `gps_rescue_ground_speed` | `500` cm/s | 5 m/s — controllable, not ambitious |
| `gps_rescue_descent_dist` | `15` m | Start descending 15 m out |

Two settings are left for you to set after checking allowed values on your firmware with
`get gps_rescue_alt_mode` and `get gps_rescue_sanity_checks`. Keep sanity checks **on** — they
abort a rescue that is not making progress toward home, which is the mechanism that turns a
misconfigured rescue into a controlled failure rather than a flyaway.

## If you decide against it

`DROP` is the honest default for a cinewhoop flown close in, and there is no shame in it:

```
set failsafe_procedure = DROP
save
```

The GPS still earns its place — home distance and direction in the OSD, and position telemetry to
the radio for finding the quad after it lands. That is most of the practical value, without the
flyaway risk.
