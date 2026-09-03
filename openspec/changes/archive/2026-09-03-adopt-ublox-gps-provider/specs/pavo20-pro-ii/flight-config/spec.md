## MODIFIED Requirements

### Requirement: A committed config SHALL NOT restate firmware defaults

A line whose value equals the firmware default for the version named in `HANDOFF.md` MUST NOT
appear in a committed config, unless an adjacent comment says why it is there.

Three such lines were identified on 2026-09-03: `set gps_auto_baud = OFF` and `set rates_type =
ACTUAL`, both confirmed equal to the 2025.12.2 default by `get`, and `set auto_profile_cell_count
= 0` on profile 2.

The cost is not the line, it is what the line implies. `diff all` emits only what differs from
default, so a reader who knows the format reads every line in these files as a deliberate
deviation. A default restated as though it were a choice invites someone to defend it, and
`CLAUDE.md` warns that pastes are chunked and that lines get dropped — a dropped line that was
doing nothing produces a hunt for a fault that does not exist.

`gps_auto_baud` was offered here as the sharp case: load-bearing as a *value* and inert as a
*line*. That reading was wrong, and how it was wrong is the more useful lesson. At `2025.12.2` the
field exists in `gpsConfig_t` (`src/main/pg/gps.h`) and is settable from the CLI
(`src/main/cli/settings.c:1137`), which is why `get gps_auto_baud` prints `OFF` — but
`src/main/io/gps.c` never reads it. The UBLOX driver baud-scans unconditionally: three `MON-VER`
attempts per rate at 330 ms each (`GPS_BAUDRATE_TEST_COUNT` and `GPS_CONFIG_BAUD_CHANGE_INTERVAL`,
`src/main/io/gps.c:90` and `:92`), stepping down through the six rates of `gpsInitData[]`
(`src/main/io/gps.c:109-116`) and wrapping. The value is inert as well as the line.

**`get` printing a value proves a setting is settable, not that anything reads it.** Only the
firmware source separates a live default from a dead one, and `get` cannot make that distinction
at all.

`gps_provider` and `gps_auto_config` replace it as the sharp case, and are a better one. At
`2025.12.2` both equal the firmware default — `.provider = GPS_UBLOX` and
`.autoConfig = GPS_AUTOCONFIG_ON` in `PG_RESET_TEMPLATE(gpsConfig_t, ...)`, `src/main/pg/gps.c` —
and both decide whether the aircraft has a GPS at all. A default that is genuinely load-bearing is
exactly what the exception below is for.

The exception exists because a default can move between firmware versions. A restated default that
is pinned on purpose is acceptable when the comment says so.

#### Scenario: A default is deliberately pinned

- **WHEN** a setting is written explicitly even though it matches the current default
- **THEN** an adjacent comment states which firmware version the default was checked against, and
  why the line is being kept

#### Scenario: Removing an inert line does not change behaviour

- **WHEN** the three identified lines are removed and the config is pasted
- **THEN** `get gps_auto_baud`, `get rates_type` and `get auto_profile_cell_count` return the same
  values as they did before the removal

#### Scenario: A setting is settable but never read

- **WHEN** a config line is defended on the grounds that `get` returns the expected value
- **THEN** the firmware source for the version in `HANDOFF.md` is checked for a read of that
  field, and a field nothing reads is recorded as inert rather than as load-bearing
