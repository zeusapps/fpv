## Context

See `proposal.md` — Why. The constraints that shape the approach:

- There is no test suite and no way to dry-run a config. Every change is verified by pasting into a
  real flight controller and observing the aircraft.
- The aircraft is currently flying and correct. The files are what is wrong. So the direction of
  correction is file ← aircraft, never the reverse.
- `dumps/BTFL_cli_backup_PAVO20PRO2_20260903_BETAFPVG473_V3 - current.txt` is a trusted capture of
  the aircraft as flown, taken 2026-09-03 and committed in `1ea8b52`.
- `PAVO20PRO2_SBUS_V1.txt` has never been pasted or flown. It cannot be verified the way the ELRS
  config can, and nothing on the aircraft depends on it today.
- The Configurator CLI drops lines from large pastes, so any edit that must be applied is applied
  in chunks and confirmed by a re-capture, not by eyeballing the paste.

## Goals / Non-Goals

**Goals:**

- Make the committed ELRS config safe to re-paste onto the flying aircraft at any time.
- Make the committed configs a truthful description of the aircraft, so the next diagnosis starts
  from a correct baseline.
- Capture the UART constraint and the disproved profile-selection hypothesis while the evidence is
  fresh.

**Non-Goals:**

- Retuning anything. No PID, filter or rate value changes in this work. Every edit is either a
  deletion of something inert or stale, or a copy of a value read off the aircraft.
- Fixing the same defect on the Meteor75 or FireFly25. See `proposal.md` — Impact.
- Testing GPS Rescue. That is `HANDOFF.md` under *GPS Rescue* and stays there. This change only
  removes a reason its first test could be sabotaged by a stale level reference.

## Decisions

### Remove the calibration rather than refresh it

The obvious alternative is to update `acc_calibration` to the aircraft's current `-37,-87,-45,1`
and keep the line. Rejected, because it fixes today's instance and preserves the mechanism: the
refreshed value is stale again after the next re-level, and there is still nothing in the file that
says when it was taken or that it has an expiry at all. The defect is not that the number is wrong,
it is that a file records a number that only the hardware can be authoritative about.

Removing the line has a property worth stating plainly: `diff all` writes only what it names, so a
config with no `acc_calibration` leaves whatever is on the board untouched. Pasting becomes
non-destructive with respect to calibration — the strongest available guarantee, and it holds
without anyone having to remember anything.

The cost is that a bare-board rebuild now needs an explicit levelling step, because there is no
longer a number to fall back on. That is the correct trade: the fallback number was never valid for
a board that had just been reflashed and remounted, it only looked like it was.

Same treatment for `acc_trim_pitch` and `acc_trim_roll`, which the same re-level cleared, and for
the same reason.

### Take the OSD positions from the capture, verbatim

The eight changed positions are copied as integers from the 2026-09-03 capture. They are not
decoded, re-derived or tidied. Decoding is used only to confirm that all eight still carry profile
bit 1 and are therefore visible — which was checked when the drift was found, and is the one
property worth confirming, since a value below 2048 is hidden and would be an invisible regression.

Hand-editing the encoded integers is what `docs/betaflight-reference.md` warns against. Copying
them wholesale from a capture is not hand-editing; it is transcription, and it is verified by
re-capture.

### Edit the SBUS config in parallel, and mark it unverified

`PAVO20PRO2_SBUS_V1.txt` gets the identical treatment because it carries the identical stale
triplet, and leaving it would mean the repo still holds a file that degrades the aircraft when
pasted. But it cannot be verified, so it is not claimed to be. Its header comment says it is
untested, and `HANDOFF.md` continues to list it as never pasted.

The alternative — leave it alone until someone flies SBUS — was rejected because the stale
calibration is the thing most likely to be applied by someone in a hurry switching to the DJI
controller, which is exactly when nobody is reading headers.

### Do not touch the trailing profile lines

See the corresponding requirement in `specs/pavo20-pro-ii/flight-config/spec.md`. The behaviour was
checked against `src/main/config/config.c` at tag `2025.12.2` rather than assumed, after the
opposite conclusion had already been stated out loud and written into a draft. It is recorded as a
requirement specifically so it reads as settled rather than as an oversight.

## Risks / Trade-offs

**A bare-board rebuild is now one step longer, and the step is easy to skip** → The levelling step
becomes explicit in `SETUP_GUIDE.md` rather than a note, and the config no longer contains a number
that makes skipping it look harmless. An unlevelled board is also immediately obvious in the
Configurator's Setup tab, which a rebuild passes through anyway.

**The paste could drop the lines being changed and nobody would notice, because the change is
mostly deletions** → Verification is a fresh `diff all` compared against the file, not a visual
check of the paste. That is the same round-trip the OSD requirement already specifies, and it
catches a dropped deletion as readily as a dropped addition.

**The OSD layout could be mid-experiment rather than settled** → It was captured from a flying
aircraft on 2026-09-03 and all eight elements are visible, but nobody has said the arrangement is
final. If it moves again, the requirement already says what to do, and the cost is one more
transcription.

**Editing a flying aircraft's config file at all** → The edits are deletions plus transcriptions
from the aircraft itself, so the file converges on what is already flying. The ELRS config is not
re-pasted as part of this work; it does not need to be, because the aircraft is already in the
state the file is being corrected towards.

## Migration Plan

There is nothing to deploy. The aircraft is already in the target state — this change moves the
files to match it.

1. Edit the files.
2. Confirm by comparison against the committed 2026-09-03 capture, with no aircraft involved.
3. The next time the ELRS config is pasted for an unrelated reason, take a fresh `diff all` and
   confirm the round-trip. Until that happens the change is verified on paper only, and
   `HANDOFF.md` says so.

Rollback is `git revert`. No aircraft state depends on it.
