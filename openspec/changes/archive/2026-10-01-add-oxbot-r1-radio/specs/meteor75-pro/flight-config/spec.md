# Spec Delta

## ADDED Requirements

### Requirement: The ELRS config SHALL enable Betaflight telemetry

`M75_PRO_ELRS_V1.txt` MUST contain `feature TELEMETRY`. It cannot be left to a default: at
Betaflight `4.5.1` the board target (`betaflight/config`, branch `4.5-config`,
`configs/BETAFPVG473/config.h`) defines no `DEFAULT_FEATURES`, so it falls back to `0`
(`src/main/config/feature.h:25-27`), and the telemetry task is only enabled and only run when the
feature is set (`src/main/fc/tasks.c:557` and `:312`; `src/main/fc/init.c:978` for its init).

Without it the aircraft sends nothing to the radio — no `RxBt`, `Curr`, `Capa`, `FM` — while the
ELRS link statistics (`1RSS`, `RQly`, `TPWR` …) still appear, because the receiver generates those
itself. That is exactly what hid the gap: the radio looked connected and populated. The feature was
absent from every capture of this aircraft, the 2026-01-30 factory original included, and was
found on 2026-09-30 when the Oxbot R1 showed no `RxBt`. Enabled and saved on the aircraft that day;
`RxBt` appeared on the radio immediately.

`M75_PRO_SBUS_V1.txt` is not bound by this requirement: the SBUS link from the DJI air unit has no
telemetry path to the radio.

The CLI's `Enabled TELEMETRY` is not evidence. At `4.5.1` `cliFeature` prints it unconditionally
after setting the flag in RAM (`src/main/cli/cli.c:3320-3323`), whether or not the feature was
already on and whether or not `save` follows.

Falsifying observation: with the ELRS config applied and the aircraft powered, the radio lists
link statistics but no `RxBt`.

#### Scenario: Telemetry reaches the radio

- **WHEN** `M75_PRO_ELRS_V1.txt` has been applied and saved, and the aircraft is powered and linked
- **THEN** the radio shows `RxBt` reading the pack voltage — about 4.2 V on a freshly charged 1S
  pack — alongside the link statistics

#### Scenario: Stored, not just set

- **WHEN** `feature` is run with no argument after a reboot
- **THEN** `TELEMETRY` is in the list
