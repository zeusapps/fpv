## ADDED Requirements

### Requirement: A value drawn from a firmware lookup table SHALL be read back after being set

Any setting whose value comes from a firmware lookup table — `failsafe_procedure`,
`gps_rescue_alt_mode`, `gps_rescue_sanity_checks`, `gps_provider` and the like — MUST be confirmed
with `get` after the paste that sets it. A config file MUST NOT be treated as applied on the basis
that it was pasted without visible complaint.

Lookup values are matched exactly. At Betaflight `2025.12.2` the CLI compares the supplied text
against the table with `strcasecmp` (`src/main/cli/cli.c:4552-4553`): case is ignored,
punctuation is not. The `failsafe_procedure` table is
`{ "AUTO-LAND", "DROP", "GPS-RESCUE" }` (`src/main/cli/settings.c:382-384`), so `GPS_RESCUE` with
an underscore is rejected — while `MAX_ALT` and `RESCUE_SANITY_FS_ONLY` are correct, because those
tables genuinely use underscores. There is no rule to infer; the separator differs per table.

The danger is not the rejection, it is what surrounds it. `CLAUDE.md` directs that experimental
blocks omit `batch start` so one bad line does not block the rest — which also means a rejected
line does not stop the paste, does not prevent `save`, and scrolls past in a CLI the user has been
told to feed in chunks. In a file containing a single `set`, the result is that `save` writes
nothing at all and the setting silently keeps its previous value.

For `failsafe_procedure` specifically that means believing the aircraft will fly home when it will
in fact cut motors and drop. The file `PAVO20PRO2_FAILSAFE_GPS_RESCUE.txt` carried the underscore
form for several days before it was caught, and had never been pasted.

`get` is the correct check rather than `diff` because a lookup value that equals the firmware
default does not appear in a `diff` at all, making a successful set and a rejected one look
identical. `get` also prints the allowed values, which is how the correct spelling is discovered
without reading the source.

#### Scenario: A lookup value is set

- **WHEN** a config line sets a value drawn from a lookup table and the batch is saved
- **THEN** `get <setting>` is run and returns the intended value, and any other result is treated
  as the paste not having taken

#### Scenario: A mistyped lookup value is pasted in a file with no batch start

- **WHEN** a file whose only `set` line carries a value absent from the table is pasted and saved
- **THEN** `get <setting>` returns the previous value, demonstrating that neither the absence of a
  reported error nor a completed `save` is evidence the setting changed

#### Scenario: The intended value equals the firmware default

- **WHEN** a lookup setting is set to a value that matches the current firmware default
- **THEN** its absence from a subsequent `diff` is not read as failure, and `get` is used to
  distinguish a value that was applied from a line that was rejected or dropped
