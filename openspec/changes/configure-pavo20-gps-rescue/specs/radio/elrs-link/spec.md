## Purpose

Governs which RC channels the ExpressLRS link actually carries between the HelloRadio V12 MAX and
the aircraft. Packet rate and switch mode jointly set a ceiling on the highest usable channel, and
a channel above that ceiling fails silently — nothing errors, nothing looks wrong, the channel
simply never moves.

## ADDED Requirements

### Requirement: An aircraft using a channel above CH9 SHALL NOT run a Full-Res 8ch link

When any flight mode is assigned above CH9, the ExpressLRS switch mode MUST NOT be `8ch`. The
combination MUST be checked whenever the packet rate is changed to a "Full" rate, because `8ch` is
only selectable there.

Read off the ExpressLRS source at **tag 3.5.6**, the version on this fleet's receivers,
`src/lib/OTA/OTA.cpp`, `GenerateChannelData8ch12ch`. Each full-resolution packet carries two groups
of four 10-bit channels plus CH5 as a single bit. The group offsets decide the ceiling:

| Switch mode | Every packet | Half rate, alternating | Never sent |
|---|---|---|---|
| `8ch` | CH1–4, CH5 (1 bit), CH6–9 | — | **CH10–16** |
| `12ch Mixed` | CH1–4, CH5 (1 bit) | CH6–9 / CH10–13 | CH14–16 |
| `16ch Rate/2` | — | CH1–8 / CH9–16 | — |

`Hybrid` and `Wide` both reach CH12 and cover 50Hz through F1000Hz; the Full-Res modes exist only
on `100Hz Full` and `333Hz Full`. So the constraint applies only on Full rates.

This is not hypothetical. The Pavo20 Pro II's GPS Rescue switch on CH10 was dead for days on
`333Hz Full` with `8ch`. Nothing in Betaflight indicated a fault, because nothing was faulty.

#### Scenario: A mode is assigned above CH9 on a Full packet rate

- **WHEN** the packet rate is `100Hz Full` or `333Hz Full` and any `aux` line references a channel
  above CH9
- **THEN** the switch mode is `12ch Mixed` or `16ch Rate/2`, and the assigned channel is observed
  moving on the Betaflight Receiver tab

#### Scenario: Switch mode is changed

- **WHEN** the ExpressLRS switch mode or packet rate is changed on the radio
- **THEN** every `aux` channel above CH5 is re-checked on the Receiver tab before the next flight

### Requirement: A channel that is not transmitted SHALL be diagnosed by its value, not its absence

Diagnosis of a dead channel MUST use the value the channel reports, not whether the Receiver tab
shows it. On a CRSF link the flight controller always presents 16 channels regardless of what the
radio sends, so a missing bar is not a possible symptom.

At Betaflight `2025.12.2`, `CRSF_MAX_CHANNEL` is `16` (`src/main/rx/crsf.h:28`) and `crsfRxInit`
assigns it to `rxRuntimeState->channelCount` unconditionally (`src/main/rx/crsf.c:629`). `MSP_RC`
reports that many values (`src/main/msp/msp.c:1317-1321`), so the Configurator draws sixteen bars
on an ELRS aircraft even when the radio transmits eight.

A channel that never arrives reads **exactly 1500**: `rxInit` presets every `rcData[i]` to `midrc`
(`src/main/rx/rx.c:307-309`) and `readRxChannelsApplyRanges` only writes indices below
`rxChannelCount` (`:402`), so an unfed channel keeps its preset forever. A bar parked dead centre
while the switch is worked is the signature.

The observation must be the value, because presence of the bar is true whether the link is healthy
or not — it fails the test of failing when the thing is broken.

#### Scenario: Channel is not being transmitted

- **WHEN** the switch is moved through its full travel and the corresponding AUX bar is read
- **THEN** it holds exactly 1500 in every switch position, identifying the channel as never
  arriving rather than misconfigured in Betaflight

#### Scenario: Channel is arriving

- **WHEN** the same switch is moved and the AUX bar moves between roughly 1000 and 2000
- **THEN** the link is carrying the channel, and any remaining fault is in the `aux` assignment
