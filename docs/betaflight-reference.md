# Betaflight CLI reference

Shared across every aircraft in this repo. Aircraft-specific values live in that quad's folder.

## `diff all` format

Config files here are Betaflight `diff all` output: only settings that differ from firmware
defaults. Applied by pasting into the Betaflight Configurator **CLI** tab.

Section order:

```
defaults nosave -> board/MCU info -> resources/timer/dma -> features -> serial ports ->
beacons -> led -> aux -> adjrange -> master settings -> PID profiles -> rate profiles -> save
```

Preserve the `batch start` / `defaults nosave` header and the `save` footer when editing.

### Paste in chunks

The Configurator CLI can silently drop lines from a large paste. On the Pavo20 this produced a
GPS fault that took a long time to attribute correctly. Paste a few lines at a time and watch for
red error text.

### `batch start` makes one bad line fatal

Inside a batch, any error causes `save` to refuse:

```
###ERROR IN save: ERRORS WERE DETECTED - PLEASE REVIEW BEFORE CONTINUING###
```

Nothing is written — the board is left untouched, which is the safe outcome, but you must fix and
re-paste. For small experimental blocks, omit `batch start` so one rejected line does not block
the rest.

## String length limits

| Setting | Limit |
|---|---|
| `profile_name` | 8 characters |
| `rateprofile_name` | 8 characters |
| `craft_name` | 16 characters |

Exceeding a limit gives `STRING MUST BE 1-8 CHARACTERS` and, inside a batch, aborts the save.

## AUX mode IDs (Betaflight permanent box IDs)

Format: `aux <index> <mode_id> <channel> <range_low> <range_high> 0 0`

| ID | Mode |
|---|---|
| 0 | ARM |
| 1 | ANGLE |
| 2 | HORIZON |
| 13 | BEEPER |
| 15 | LEDLOW (LED strip off) |
| 35 | TURTLE (flip over after crash) |
| 36 | PREARM |
| 40 | USER1 (`VTX PWR` on the Cube board) |

Channel numbers are **0-indexed**: `0`=AUX1/CH5, `1`=AUX2/CH6, `2`=AUX3/CH7, `3`=AUX4/CH8,
`4`=AUX5/CH9.

## Serial port function bitmask

`serial <id> <function_bitmask> <msp_baud> <gps_baud> <telemetry_baud> <blackbox_baud>`

Note the second baud field is the **GPS** rate, not telemetry.

| Bit | Function |
|---|---|
| 0 | disabled |
| 1 | MSP |
| 2 | GPS |
| 64 | SERIAL_RX |
| 128 | BLACKBOX |
| 1024 | ESC_SENSOR |
| 2048 | VTX_SMARTAUDIO |
| 8192 | VTX_TRAMP |
| 131072 | VTX_MSP |

`131073` = `131072 + 1` = VTX_MSP + MSP — the DJI air unit port.

Older dumps use a numeric index (`serial 0` = UART1, `serial 3` = UART4); newer ones name the port
(`serial UART1`). Both forms are accepted.

## OSD element positions

```
value = x_low5 | (y << 5) | (x_bit5 << 10) | (profile_flags << 11)

profile 1 = +2048    profile 2 = +4096    profile 3 = +8192
```

**A value below 2048 is hidden.** The profile flag is what makes an element visible — to reveal an
element, add 2048 to its position. Bit 10 extends the X range beyond column 31 for HD canvases.

Prefer the Configurator **OSD** tab over hand-editing these integers.

### Digital vs analog canvas

With an air unit over MSP DisplayPort the OSD canvas is rendered by the VTX, so its size differs
from analog. `status` reports it, e.g. `OSD: MSP (53 x 20)` versus 30x16 for analog PAL. Positions
copied from an analog build land in the wrong place.

## Things that look like faults and are not

| Symptom | Cause |
|---|---|
| Radio announces **"Sensor lost"** after a CLI command | Betaflight skips the telemetry task whenever the CLI is open — `if (!cliMode && featureIsEnabled(FEATURE_TELEMETRY))` in `fc/tasks.c` |
| Buzzer silent on USB | Suppressed when the `ON_USB` beeper is off, **no battery is present**, and USB or the Configurator is active. Plug a battery in and it beeps. |
| `GPS: connected` with the module unplugged | Derived from the driver state machine only. On the NMEA provider it advances without receiving any data. |
| OSD altitude reads your ground elevation | The altitude zero point is set at **arming**, not at boot, and GPS reports height above sea level. |
| Configurator drops to the Welcome screen during `gpspassthrough` | `serialPassthrough()` runs `while (1)` and halts the scheduler. Reboot to exit. |

## Useful CLI commands

| Command | Purpose |
|---|---|
| `diff all` | Full configuration dump — what these files are |
| `status` | Sensors, GPS state, CPU, voltage, arming disable flags |
| `get <partial_name>` | Show matching settings with current value **and allowed values** |
| `resource show` | Every pin and what owns it |
| `dma show` | DMA channel ownership |
| `timer show` | Timer assignments |
| `play_sound` | Drive the buzzer directly, bypassing all conditions |
| `beeper` / `beacon` | List buzzer / DShot-beacon conditions |
| `gpspassthrough` | Bridge the GPS UART to USB. **Halts the flight controller** — reboot to exit. |
| `bind_rx` | Put an ELRS receiver into bind mode |

`get` is the reliable way to discover valid values for a lookup setting on *your* firmware, rather
than guessing a name and having it abort a batch.
