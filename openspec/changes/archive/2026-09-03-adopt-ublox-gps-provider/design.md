## Context

See `proposal.md` — Why. Three constraints shape the approach.

**There is no test suite.** Verification is a paste into a real flight controller, a `diff all`, and
an observation on the aircraft. Every claim this change makes is either cited to Betaflight source
at `2025.12.2` or to something seen on the hardware on 2026-09-03.

**Two of the three new values are firmware defaults**, so they will not appear in a `diff all`.
That collides with the existing rule in `pavo20-pro-ii/flight-config` against restating defaults,
which is why this change exercises that rule's pinning exception rather than working around it.

**The disproven claim is load-bearing in both directions.** It is not merely stale: two committed
configs carry an explicit `Do not set gps_provider = UBLOX` instruction, and two spec requirements
rest their rationale on it. Correcting the configs without correcting the specs would leave the
specs contradicting the aircraft.

## Goals / Non-Goals

**Goals:**

- Bring the committed configs into agreement with the aircraft as it now flies.
- Remove an instruction that is actively wrong, and leave behind why it was believed.
- Keep both spec requirements intact while replacing the evidence under them.
- Record the widget defect precisely enough that it can be fixed later without re-deriving it.

**Non-Goals:**

- Fixing the GPSQR widget. The fix needs an observation on the radio that has not been taken.
- Touching the Meteor75 Pro or FireFly25. Their providers were never in question here, and
  `CLAUDE.md` forbids acting on one aircraft from a finding on another.
- Pasting the GPS Rescue failsafe config. Still untested, still gated on `FAILSAFE.md`.
- Any PID, rate, motor, OSD or failsafe change.

## Decisions

### Adopt UBLOX rather than revert to NMEA

NMEA is the known-flown configuration, and reverting would be the conservative move. Rejected
because the benefit is concrete and asymmetric with the cost.

At `2025.12.2`, `PG_RESET_TEMPLATE(gpsConfig_t, ...)` in `src/main/pg/gps.c` sets
`.gps_ublox_acquire_model = UBLOX_MODEL_STATIONARY` and
`.gps_ublox_flight_model = UBLOX_MODEL_AIRBORNE_4G`. With `gps_auto_config = ON` Betaflight sends
those dynamic platform models to the module, along with the nav rate and the trimmed message set.
Under NMEA it sends nothing, and the module runs whatever the factory shipped for both cold-start
and flight. For an aircraft whose outdoor fix had never been confirmed until this change, the
stationary acquisition model is the most valuable single item on that list.

Alternatives considered:

- **Stay on NMEA.** Discards a verified improvement to keep a workaround whose justification is
  gone.
- **UBLOX with `gps_auto_config = OFF`.** Detection would still succeed — `autoConfig` is read only
  at `GPS_STATE_CONFIGURE`, after detection (`src/main/io/gps.c:1114`) — but the module would keep
  emitting factory-default NMEA while the driver expected UBX. That is a passing test that looks
  like a failure, and it forfeits every benefit above.

### Pin all three GPS lines explicitly, including the two that are defaults

The alternative is to write only `gps_ublox_use_galileo` and let the other two ride on the
defaults. Rejected: their absence would then be indistinguishable from a line dropped by a chunked
paste, which `HANDOFF.md` records as having already caused one misattributed GPS fault. The
`flight-config` exception exists for exactly this case and requires the comment to name the
firmware version, which makes the next version bump a readable check rather than an archaeology
exercise.

### Correct the disproven claim in place rather than deleting it

`CLAUDE.md`: keep a disproven hypothesis and say so — the record of what was ruled out is often
more useful than the conclusion. The failure mode here is worth preserving because it is subtle:
the claim was true when written, and was invalidated by a rewire performed for an unrelated reason.
Nobody wrote it carelessly; it simply outlived its evidence.

### Revise spec rationales, leave spec requirements alone

Both affected requirements survive unchanged as rules. Only their worked examples were falsified,
and in both cases the correction strengthens the rule — `gps_provider` is a better example of a
load-bearing default than `gps_auto_baud` ever was, and a value that silently changed between
2026-09-02 and 2026-09-03 is a better argument for the radio/aircraft split than a value that was
merely wrong from the start.

### Record the widget defect without fixing it

The fix direction is known and sound: `crsfFrameGps()` in `src/main/telemetry/crsf.c` writes
`gpsSol.numSat` as the final byte of the same frame that carries the coordinates, so a satellite
count reaches the radio. What is unknown is which EdgeTX telemetry sensor exposes it on the V12
MAX. `CLAUDE.md` is explicit that the widget has no interpreter, emulator or harness in this repo,
so guessing a sensor name would ship an untestable change to the one tool whose entire job is
telling the user where to walk.

## Risks / Trade-offs

**UBLOX needs the FC→module transmit line at every boot; NMEA does not.** That path runs through a
solder joint made on 2026-09-01 on an airframe that vibrates → NMEA stays documented as the first
recovery step in `GPS_SETUP.md`. Bounded: `allowArmingWithoutFix` defaults to `false`
(`src/main/pg/gps_rescue_multirotor.c:53`), so a failed detection blocks arming rather than
permitting a GPS-less launch.

**The config edits have not been round-tripped.** The UBLOX settings were applied from the
Configurator, not by pasting an edited file, so no capture yet proves the edited configs produce
this aircraft state → a task requires a paste and a fresh `diff all` before the change is archived.
This is the same residual risk `HANDOFF.md` already carries from the 2026-09-03 reconciliation, and
this change is the opportunity to close both.

**The widget still ships the defect.** Until fixed, a no-fix position is displayed and saved as
though it were real → recorded in `radio/CODE_REVIEW.md` and `HANDOFF.md` with the operating rule,
and the poisoned save file is deleted as part of this change.

**Constellation mix is unconfirmed.** Ten satellites were seen with Galileo enabled, but whether
Galileo satellites are actually being tracked was not checked — the observed list showed GPS and
BeiDou → checked outdoors as a task, non-blocking, since the fix works either way.

**Fix quality in flight is unproven.** The balcony observation was stationary and under partial
sky. This change must not be read as clearing GPS Rescue for testing; that remains gated on
`FAILSAFE.md`.

## Migration Plan

1. Edit the configs, then paste and re-capture — the aircraft is the reference, not the file.
2. Documentation and specs follow the confirmed capture.
3. Rollback is two lines, `set gps_provider = NMEA` and `set gps_auto_config = OFF`, plus a full
   power cycle so the module's RAM-layer configuration reverts. Every VALSET in
   `src/main/io/gps.c` uses `UBX_VAL_LAYER_RAM`, so nothing Betaflight wrote to the module
   survives loss of power.

## Open Questions

- Which EdgeTX telemetry sensor exposes the CRSF satellite count on the V12 MAX. Needed to fix the
  widget; not needed to record the defect, and does not affect this change's specs or tasks.
- Whether the Meteor75 Pro and FireFly25 would also benefit from UBLOX. Deliberately deferred —
  neither has a GPS fault, and acting on them from this aircraft's finding is exactly what
  `CLAUDE.md` warns against.
