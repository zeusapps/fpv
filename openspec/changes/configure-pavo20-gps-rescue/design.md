## Context

See `proposal.md` — Why. The state that shapes the approach:

- The aircraft is on `failsafe_procedure = GPS-RESCUE`, set by the pilot and read back
  2026-10-02. Until then it was on `DROP_IT` (the firmware default, absent from the capture), and
  this change originally planned to leave it there.
- `aux 6 46 5 1700 2100 0 0` is applied; AUX 6 moves on the Receiver tab.
- The tuning block is pasted and verified. Five non-default `gps_rescue_*` lines appear in a
  `diff`; the six that equal the `2025.12.2` default correctly do not.
- One field attempt exists, on 2026-09-03, at 20–30 m with ~26 satellites. The aircraft came down
  and the motors appeared to stop. **No log was taken**, so nothing about it can be re-examined.
- There is no test suite and no simulator. The only verification is flying it, and that is
  deliberately outside this change.

The constraint that drives everything below: we are acting on a **hypothesis** about why the
aircraft came down, and we cannot confirm it from here. The design therefore has to be sound
whether or not the hypothesis is right.

## Goals / Non-Goals

**Goals:**

- Correct the most probable cause of the failed attempt, with a change that is defensible on its
  own merits even if it turns out not to have been the cause.
- Make the next attempt produce evidence, so a second inconclusive result is not possible.
- Leave the arming step as a single, gated, verifiable action.

**Non-Goals:**

- Flying the rescue, or asserting that GPS Rescue works on this aircraft. No artifact here may
  claim qualification.
- Tuning the rescue's flight behaviour — velocity gains, yaw, rotation. Those are only meaningful
  once the aircraft can hold altitude during a rescue at all.
- Touching the other two aircraft. The ELRS channel-ceiling requirement is written to be
  fleet-applicable, but nothing on the Meteor75 or FireFly25 is changed.

## Decisions

### Set `ap_hover_throttle` from the throttle curve now, and require a measured hover before flying

`thr_hover = 34` puts the airframe's hover point at 34%, so `1340` on the 1000–2000 scale. That is
derived from a value already committed for this aircraft, so it is available without flying.

Alternatives considered. *Leave it at the `1275` default* — rejected: it is the single most
probable cause, and the default is a generic figure that cannot know this airframe. *Demand a
measured hover before changing anything* — rejected as the only step, because it blocks all
progress on a flight the pilot has not made yet; but kept as a **required refinement** in the
spec, because the throttle curve's hover point is the pilot's stated intent rather than a
measurement of what the aircraft does. A ducted quad carrying an O4 Pro on a worn pack may hover
higher.

So: set `1340` now, and require the OSD hover reading to confirm or correct it before the rescue
is flown. If the measurement disagrees, the measurement wins.

*Addendum 2026-10-02:* it did. The pilot read ~42% on a 4S 850 mAh pack on 2026-10-01, during a
rescue that oscillated with `1340` set. The committed value is now `1420`.

### Choose `debug_mode = RTH` over `AUTOPILOT_ALTITUDE`

Only one debug mode can be active, so this is a real choice.

`AUTOPILOT_ALTITUDE` would show commanded throttle and each altitude PID term — apparently the
most direct evidence for the hover-throttle hypothesis. It is nevertheless the wrong pick, because
**blackbox already logs the things it would tell us**: altitude, motor outputs and RC command are
recorded natively. What is *not* otherwise recoverable is the rescue's internal state — which
phase was active, which failure code was set, and whether `secondsFailing` was counting.

`DEBUG_RTH` carries exactly that: max altitude in slot 0, `failure * 10 + phase` in slot 2,
`secondsFailing * 100 + secondsLowSats` in slot 3. That distinguishes the hypothesised
`ATTAIN_ALT → LANDING → ABORT` sequence from every other disarm path, which is the actual open
question. If the next log shows the aircraft never left `ATTAIN_ALT` with `secondsFailing`
climbing, the hypothesis is confirmed; if it shows a different phase or failure, we learn
something the altitude terms would not have told us.

`debug_mode` is currently `GYRO_FILTERED`, which is filter-tuning instrumentation and not in use.

### Keep the two-block split, and keep block 2 unpasted

*Superseded 2026-10-02 for the second half.* The pilot pasted block 2 after the 2026-10-01 rescue
came home, and chose to keep it after being told what was unproven. The split itself stands: it is
still what lets the parameters change without touching lost-link behaviour, and block 2's
checklist is now the record of which gates were unmet when it was armed.

The alternative — one file with a loud comment above the arming line — was rejected. A comment does
not survive the operation the repo actually performs, which is selecting part of a file and pasting
it into a CLI in chunks. Physical separation into two files does.

Block 1 is pasted deliberately *before* testing rather than after, which inverts the original
document's instruction. The reason is in the failsafe spec: the default `gps_rescue_ascend_rate`
of `750` cm/s demands a climb this airframe cannot produce, so testing on defaults tests a
different aircraft — and is itself a plausible contributor to the failed attempt.

### Do not lower `gps_rescue_min_start_dist` to make close tests possible

Tempting, because the pilot tested close. Rejected: the threshold exists to stop the aircraft
flying home *at* the pilot from short range. The correct response to "the test distance was
awkward" is to stand further away, which costs nothing.

### Keep `gps_rescue_sanity_checks = RESCUE_SANITY_FS_ONLY`, and stop claiming it is protection

`FS_ONLY` remains correct: during a real failsafe it behaves identically to `ON`, because a real
failsafe *is* hard Rx loss, and during a switch-induced test it gives 20 s of hover instead of
disarming.

What changes is the claim made about it. The climb-failure path
(`gps_rescue_multirotor.c:434-460`) explicitly **ignores the sanity mode** and forces
`RESCUE_LANDING` regardless. So `FS_ONLY` does not make a switch test non-destructive; it narrows
which failures are recoverable. The documentation must not offer it as a safety net it is not.

## Risks / Trade-offs

- **The hover-throttle hypothesis is wrong** → The instrumentation decision is deliberately
  independent of it: `RTH` logging distinguishes the hypothesised path from the alternatives, so a
  wrong hypothesis still yields a diagnosis rather than another inconclusive flight.
- **`1340` is itself wrong for this airframe** → It is bounded and self-correcting: too low
  reproduces the sink, too high shows as an unwanted climb at rescue onset, and both are visible in
  the first seconds with the switch in hand. The spec requires the measured hover to override it.
- **The aircraft genuinely cannot climb at 2 m/s carrying an O4 Pro** → Then the correct outcome is
  not a tuning change but a revert to `DROP`. `FAILSAFE.md` already documents `DROP` as the honest
  default for this class of aircraft.
- **A real failsafe now runs a rescue that has never been seen to land** (added 2026-10-02) → The
  descent, landing and touchdown disarm have not run on this aircraft, and on hard Rx loss
  `FS_ONLY` disarms on any sanity failure. Mitigated only by the next logged switch test being
  allowed to land unaided, and by the revert below. The GPSQR widget is the recovery aid if it
  comes down elsewhere.
- **Attention has been on the rescue while the real gate is elsewhere** → GPS has still never been
  shown to hold a fix while *moving*, with motors running and the O4 transmitting. The 26-satellite
  reading was good but stationary readings have flattered this aircraft before. Tasks keep this
  visible rather than letting the rescue work imply it.

## Migration Plan

Rollback is `set failsafe_procedure = DROP` and `save`, then `get failsafe_procedure` to confirm
it returns `DROP` — the same read-back the flight-config spec requires, for the same reason. Apply
it if a logged rescue disarms in the air, flies away, or does not descend.

*Superseded 2026-10-02:* this section said rollback was "the absence of an action" because the
aircraft would stay on `DROP`. Block 2 is applied, so it no longer is.

## Open Questions

- **Was the hover throttle the cause?** Deferred by construction: it is answered by the
  instrumented flight, which is the pilot's and outside this change. It does not alter the specs,
  the approach or the tasks — every one of them is written to hold whichever way it resolves.
- **Whether the motors stopped in the air or on impact.** Unrecoverable from the 2026-09-03
  attempt; the next log settles it via the phase and failure code.
