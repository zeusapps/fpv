# GPS Setup — BZGNSS BZ-181 on the Pavo20 Pro II 4S (Cube G473_V3)

> ## RESOLVED — 2026-09-01
>
> **Cause:** the GPS module's TX was soldered to **R1 (PA10)**, which the board also routes to the
> **DJI O4 air unit's SBUS output**. Two push-pull drivers on one net. With the air unit connected,
> the GPS data was corrupted at bit level; `SENSOR_GPS` never set, so Betaflight rendered no GPS
> OSD elements at all.
>
> **Fix:** moved the GPS to **UART2** and the LED strip data line to **T1 (PA9)**, per BetaFPV's
> own 2025.12.5 reorganisation. Three wires:
>
> | Wire | From | To |
> |---|---|---|
> | LED yellow (data) | R2 (PA3) | T1 (PA9) |
> | GPS yellow (module TX) | R1 (PA10) | R2 (PA3) |
> | GPS white (module RX) | T1 (PA9) | T2 (PA2) |
>
> Config: `PAVO20PRO2_ELRS_V1.txt`. GPS runs **NMEA at a fixed 115200**, auto-baud and auto-config
> off — this module never answers UBX `MON-VER`, so the UBLOX provider cannot complete baud
> detection. **Confirmed working with the air unit connected.**
>
> This also frees R1 for its intended purpose, making the DJI Remote Controller 3 usable —
> see `PAVO20PRO2_SBUS_V1.txt` and `BINDING_GUIDE.md`.
>
> ### Things that looked like the fault and were not
>
> | Symptom | Actually |
> |---|---|
> | `GPS: connected` in `status` | Meaningless on NMEA — reads true with the module unplugged |
> | "Sensor lost" on the radio | The CLI disables the telemetry task |
> | Garbled `gpspassthrough` output | Real, but passthrough also halts the scheduler, so it was an unfair test with the O4 attached |
> | `version = unknown` | Expected on NMEA; only meaningful on UBLOX |
> | Empty GPS OSD elements | Correct behaviour — Betaflight omits them entirely until `SENSOR_GPS` sets |
>
> Ruled out along the way: baud rate, module health, 5 V supply, solder joints, swapped wires,
> connector orientation, LED strip, DMA conflicts, resource conflicts, RF interference, grounding.
>
> The rest of this document is the working record, kept for the mechanisms it explains.


## The module

| Item | Value |
|---|---|
| Model | BZGNSS BZ-181 |
| Chip | u-blox **M10** (M10050), 72 channels |
| Constellations | GPS, GLONASS, BDS, GALILEO, SBAS, QZSS |
| **Default baud** | **115200** (confirmed in the BZGNSS manual; some retail listings wrongly say 9600) |
| Default update rate | 10 Hz |
| Protocol | dual — UBLOX or NMEA |
| Power | **5V** |

M10 needs a reasonably recent Betaflight to use the UBLOX protocol properly. On 2025.12.2 that is fine.

## ACTION PLAN — moving GPS to UART2

### Step 1: confirm the contention (1 minute, do this first)

Battery disconnected, multimeter in continuity mode. **Probe the R1 pad against each of the six
pins of the O4 connector in turn.**

Do not try to identify the SBUS pin first. BetaFPV have not published a pinout for this socket, and
the DJI flying-lead convention below is community-documented rather than official:

| Pin | Colour | Function |
|---|---|---|
| 1 | Black | GND |
| 2 | Red | VBAT |
| 3 | Yellow | RX (from FC TX) |
| 4 | White | TX (to FC RX) |
| 5 | **Green** | **SBUS** |
| 6 | Black | GND |

Sweeping all six pins avoids depending on any of that:

| Result | Meaning |
|---|---|
| One pin beeps against R1 | Confirmed — the air unit is tied to PA10 alongside the GPS module's TX. Proceed. |
| No pin beeps | The theory is wrong. SBUS reaches RX1 another way, or not at all. **Stop — do not rewire.** |

### Step 2: get BetaFPV's 2025.12.5 files

From the [Pavo20 Pro II 4S CLI page](https://support.betafpv.com/hc/en-us/articles/59491910094361-CLI-and-Firmware-for-Pavo20-Pro-II-4S-Cube-2-4S-30A-FC), download:

- `BF2025.12.5 Cube G473_30A_Pavo20 Pro II_ELRS 20260812.hex`
- `BF2025.12.5 Cube G473_30A_Pavo20 Pro II_ELRS 20260812.txt`

**Use their CLI dump as the base for the new layout.** It already contains the correct `resource`,
`timer` and `dma` lines for the LED strip on TX1 (PA9) — values that are fiddly to derive by hand
and easy to get wrong. Do not hand-write the LED remap.

### Step 3: rewire three wires

| Wire | From | To |
|---|---|---|
| LED yellow (data) | R2 (PA3) | **T1 (PA9)** |
| GPS yellow (module TX) | R1 (PA10) | **R2 (PA3)** |
| GPS white (module RX) | T1 (PA9) | **T2 (PA2)** |

The LED strip's red and black stay on the battery input pads. The buzzer is untouched.

This frees **R1 (PA10)** for the O4's SBUS, which is what makes the DJI Remote Controller 3 usable.

### Step 4: flash and configure

1. Flash the 2025.12.5 ELRS hex, **full chip erase**
2. Paste BetaFPV's stock CLI dump
3. Apply the GPS settings and this quad's AUX layout on top
4. **Re-run accelerometer calibration** — `acc_calibration` is per-airframe and the erase clears it

### Step 5: verify

With the O4 connected and a battery in, open the Configurator **GPS** tab and look for a satellite
count. That is the whole test — `status` will not tell you anything (see the control test above).

Then take it outside with clear sky for 5-15 minutes for the first cold-start fix.

---

## Official BetaFPV documentation

Two relevant articles. Both are served from a Zendesk help centre that rejects plain fetches, so
open them in a browser.

### 1. GPS installation guide

**["How to assemble GPS and BB beeper"](https://support.betafpv.com/hc/en-us/articles/50605134998809-How-to-assemble-GPS-and-BB-beeper)** — BetaFPV, updated 19 Sep 2025.

Written for the Pavo20 / Pavo20 Pro (F4 2-3S 20A AIO), not the Cube board specifically, but the
wiring rule and the configuration sequence are the same. Key content, quoted:

> RX point on GPS connects to TX joints on FC, TX point connects to RX joints.
> GPS connects to UART1 port for example

Which matches this quad's install exactly. Their configuration sequence:

1. **Ports** page — set sensor input on UART1 to GPS, set baudrate to **AUTO**, save and reboot
2. **Configuration** page — enable the GPS option, save and reboot
3. **GPS** page — set the GPS protocol correctly, enable **Auto config**, save and reboot
4. Reconnect the battery and wait for the GPS icon to light

> (If the GPS icon is red, it needs to go outside the room to pick up signals. If there is no GPS
> icon lighting up, make sure the connection and configuration are all correct.)

**Note where this diverges from what works on this quad.** BetaFPV's recommended `AUTO` baud with
auto-config assumes the UBLOX provider and a module that answers `MON-VER`. This BZ-181 does not,
so following the official steps verbatim leaves the driver stuck in `DETECT_BAUD`. The working
configuration here is NMEA at a fixed 115200 with auto-config off.

The article also covers adding a magnetometer, which needs the 6-pin variant and extra soldering:

```
resource I2C_SCL 1 B08
resource I2C_SDA 1 B09
set mag_i2c_device = 1
save
```

plus `set i2c1_pullup = ON` on boards without a pull-up resistor.

### 2. Firmware and stock CLI for this exact board

**[CLI and Firmware for Pavo20 Pro II 4S (Cube 2-4S 30A FC)](https://support.betafpv.com/hc/en-us/articles/59491910094361-CLI-and-Firmware-for-Pavo20-Pro-II-4S-Cube-2-4S-30A-FC)** — updated 19 Aug 2026.

Carries the official `.hex` firmware and stock `.txt` CLI dumps, in separate ELRS and SBUS builds.

## Module wiring, LED and mounting

**The cable has five wires, and one of them is a decoy:**

| Colour | Signal | Goes to |
|---|---|---|
| Red | 5V | FC 5V pad |
| Black | GND | FC GND |
| **Yellow** | **module TX** | **FC RX1 (PA10)** |
| **Grey** | **module RX** | **FC TX1 (PA9)** |
| Green | **Spare GND** | nothing, or GND |

The green wire is a *second ground*, not a signal. Wiring green to a UART pad in place of the
yellow TX gives a four-wire install that looks complete and cannot possibly work — the FC would
receive nothing while every joint looks fine. **Verify yellow is the wire on RX1.**

### The connector cannot be plugged in backwards

The module takes a plug rather than direct solder. That raises the obvious question of whether it
is mated the wrong way round — but the pad order rules it out:

```
GND | TX | RX | 5V
```

**GND and 5V sit at opposite ends.** A reversed plug would put 5V on the GND pad and GND on the 5V
pad. The module would not power up at all, and would most likely be damaged. Since it powers up and
holds a 3D fix, the plug is seated the correct way round — and therefore TX and RX are landing on
the correct pins too.

This also means a swapped-signal fault is off the table for this build, provided the harness itself
is wired to the connector conventionally.

### BZ-181 module pinout (from the manufacturer diagram)

Pad order on the module, left to right:

| Pad | Connects to |
|---|---|
| GND | FC GND |
| **TX** | **FC RX** |
| **RX** | **FC TX** |
| 5V | 5V input |

Standard crossover. So `module TX -> FC R1 (PA10)` and `module RX -> FC T1 (PA9)` is the correct
target wiring for this quad.

### Settling the swap question with a continuity test

The pinout diagram does not show wire colours, so it cannot tell you which wire sits on which pad.
Do not reason about colours — measure. Multimeter in continuity/diode mode, battery disconnected:

| Probe A | Probe B | Expected |
|---|---|---|
| Module **TX** pad | FC **R1** pad | beep |
| Module **RX** pad | FC **T1** pad | beep |

**Probe with the connector mated, from the module end.** Testing from the harness plug to the FC
only proves the wires and the FC joints. It does not cover the crimp inside the connector housing
or the mating of the plug itself — which on this quad is the one remaining untested link in the
chain. Measured 2026-09-01: harness-plug-to-FC checks all pass, bridges all clear.

If instead the module **TX** pad beeps against the FC **T1** pad, the two signal wires are
transposed — resolder them and no configuration change is needed.

**Also check for a bridge.** The GPS signal wires land on adjacent pads, and the joints on this
quad are generously tinned:

| Probe A | Probe B | Expected |
|---|---|---|
| FC **R1** pad | FC **T1** pad | **no beep** |
| FC **R1** pad | nearest GND | **no beep** |
| FC **T1** pad | nearest GND | **no beep** |

A solder bridge between R1 and T1 shorts the FC's own transmit line onto its receive line. The
module's much weaker drive then loses against the FC's push-pull output, and the FC hears either
its own echo or nothing at all — producing exactly the observed behaviour: a healthy module with a
3D fix, a port that opens cleanly, and not one frame parsed. A bridge to GND is equally fatal and
just as easy to miss under flux residue.

This is definitive and takes under a minute. It removes every remaining assumption about which
colour carries which signal.

### The cable on this quad is the 4-wire variant

BZGNSS ship more than one harness. The manual documents a 5-wire cable (red / black / yellow /
grey / green-spare-GND). **This quad has a 4-wire cable: black, yellow, white, red**, currently
soldered as:

| Colour | Soldered to | Assumed to be |
|---|---|---|
| Red | 5V | 5V |
| Black | GND | GND |
| Yellow | **R1** (PA10) | module TX |
| White | **T1** (PA9) | module RX |

Power is confirmed good — the module runs and the PPS lamp reaches its fix state.

**Do not assume yellow is TX on this harness.** The colour convention is only documented for the
5-wire cable, and white is not in that table at all. If yellow is actually the module's *RX* and
white its *TX*, then both directions are dead at once: the FC listens to the module's RX pin and
talks into the module's TX pin. That single fault explains everything observed — UBLOX never gets
a `MON-VER` reply, and NMEA reaches `RECEIVING_DATA` but parses nothing, because no bytes ever
reach PA10.

**Test: swap yellow and white at the FC end.** Yellow to T1, white to R1. No settings change
needed — leave the NMEA config in place and re-check `status` and the OSD.

Before desoldering, two non-invasive checks:

- **`gpspassthrough`** — if nothing appears, no data is reaching PA10 and the swap is worth doing.
- **Multimeter, DC volts, FC `R1` pad to GND, module powered.** An idle-or-transmitting UART TX
  line sits near 3.3 V (a little under while data flows). A reading of ~0 V or a floating value
  means that pad is not being driven by the module, i.e. the wrong wire is on it.

### PPS LED — the fastest health check

The red **PPS** lamp is **off** whenever the module has no position, and **flashes** once a 3D fix
is acquired.

| PPS LED | Meaning |
|---|---|
| Flashing | Module is powered, working, and has a 3D fix. Any remaining fault is the FC link. |
| Off outdoors after several minutes | No fix — bad antenna orientation, poor sky view, or the module is not powered. |

This is independent of Betaflight entirely, so it splits the problem cleanly in two.

### Mounting

The ceramic patch antenna must face **up, toward the sky** — the module is marked on that face.
Mounted upside down under a canopy it may never achieve a fix outdoors.

## How it is wired on this quad

Taken from the actual `diff all` in `dumps/`:

```
resource LED_STRIP 1 A03       # PA3 = UART2_RX pad — LED strip lives here
resource SERIAL_TX 2 NONE      # UART2 disabled
resource SERIAL_RX 2 NONE
serial UART1 2 115200 57600 0 115200   # UART1 = GPS  (function 2)
serial UART3 64 115200 57600 0 115200  # UART3 = ELRS (function 64)
                                       # UART4 = DJI O4, board default, not in diff
```

Board pins (from the `BETAFPVG473_V3` Betaflight target):

| Signal | Pin |
|---|---|
| UART1 TX | PA9 |
| **UART1 RX** | **PA10** ← GPS module's **TX** wire goes here |
| UART2 TX | PA2 |
| UART2 RX | PA3 — repurposed as LED_STRIP |
| UART3 TX/RX | PB10 / PB11 (ELRS) |
| UART4 TX/RX | PC10 / PC11 (DJI O4) |
| LED_STRIP (target default) | PB2 |

> **Note:** BetaFPV's own documentation puts GPS on **UART2** and moves the RGB LED wire to the
> **TX1** pad. This quad does the opposite — LED on the RX2 pad, GPS on UART1. Both are valid;
> just be aware the official BetaFPV instructions will not match what is on this airframe.

> **Warning:** `resource LED_STRIP 1 A03` is a remap away from the target default (PB2). A
> **full chip erase** when flashing firmware will wipe it and the LED strip will stop working
> until you re-apply the `resource`, `timer` and `dma` lines from the dump.

---

## Diagnosis: "no GPS elements in the OSD" is a specific, meaningful symptom

This is not the same as "GPS has no fix", and the difference is the whole diagnosis.

In `osd_elements.c`, Betaflight builds its render list like this:

```c
void osdAddActiveElements(void)
{
    ...
#ifdef USE_GPS
    if (sensors(SENSOR_GPS)) {
        osdAddActiveElement(OSD_GPS_SATS);
        osdAddActiveElement(OSD_GPS_SPEED);
        osdAddActiveElement(OSD_GPS_LAT);
        osdAddActiveElement(OSD_GPS_LON);
        osdAddActiveElement(OSD_HOME_DIST);
        osdAddActiveElement(OSD_HOME_DIR);
        ...
```

GPS elements are only drawn at all when **`SENSOR_GPS` is set**. And in `gps.c`:

```c
static void gpsHandleFrameComplete(void)
{
    if (gpsData.state == GPS_STATE_RECEIVING_DATA) {
        gpsData.lastNavMessage = gpsData.now;
        sensorsSet(SENSOR_GPS);      // <-- no fix required
    }
    ...
}
```

`SENSOR_GPS` is set as soon as the FC **parses a complete nav frame** — a satellite fix is *not*
required. A working u-blox module sitting indoors with zero satellites still streams valid frames.

So the two symptoms mean different things:

| Symptom | Meaning |
|---|---|
| Elements show **zeros / NC** | GPS is talking to the FC. No fix yet. **This is correct behaviour** — it is what the FireFly does. |
| Elements show **nothing at all** | `SENSOR_GPS` is never set. The FC is **not parsing any GPS data**. Wiring, baud or protocol problem. |

The OSD element positions on this quad are already correct and already visible — all of these have
the profile-1 visible flag (bit 11, value 2048) set:

| Setting | Value | Decoded |
|---|---|---|
| `osd_gps_sats_pos` | 2146 | visible, col 2, row 3 |
| `osd_gps_speed_pos` | 2114 | visible, col 2, row 2 |
| `osd_gps_lat_pos` | 2135 | visible, col 23, row 2 |
| `osd_gps_lon_pos` | 2103 | visible, col 23, row 1 |
| `osd_home_dist_pos` | 2178 | visible, col 2, row 4 |
| `osd_home_dir_pos` | 2424 | visible, col 24, row 11 |
| `osd_altitude_pos` | 3141 | visible, col 37, row 2 (uses the HD extended-X bit) |

**So the OSD is not the problem.** Do not go re-arranging the OSD tab. Fix the data link.

### The OSD element list is not stale — Betaflight rebuilds it

A reasonable theory is that the OSD builds its element list at boot, before the GPS comes up, and
never refreshes. That is **not** what happens. `osd.c` watches the sensor flag every update:

```c
#ifdef USE_GPS
    static bool lastGpsSensorState;
    // Handle the case that the GPS_SENSOR may be delayed in activation
    // or deactivate if communication is lost with the module.
    const bool currentGpsSensorState = sensors(SENSOR_GPS);
    if (lastGpsSensorState != currentGpsSensorState) {
        lastGpsSensorState = currentGpsSensorState;
        osdAnalyzeActiveElements();
    }
#endif
```

So the moment `SENSOR_GPS` flips true, the GPS elements appear — no reboot needed.

**The contrapositive is the diagnosis: if the GPS elements are not on screen, `SENSOR_GPS` is
false, and no nav frame has been parsed.** This holds regardless of what `status` says about
being "connected", because on the NMEA path the state machine advances without any data.

### Position encoding, for reference

```
value = x_low5 | (y << 5) | (x_bit5 << 10) | (profile_flags << 11)
profile 1 = +2048, profile 2 = +4096, profile 3 = +8192
```

A value **below 2048** is hidden. To reveal an element, add 2048 to its position.

---

## What `status` tells us

```
GPS: NOT CONNECTED, UART1 19200 (set to AUTO), NOT CONFIGURED, version =  unknown
OSD: MSP (53 x 20)
```

Read that carefully — every field is diagnostic:

| Field | Meaning |
|---|---|
| `UART1` | Port assignment is **correct**. |
| `19200 (set to AUTO)` | `gps_auto_baud = ON`; the driver is mid-cycle, currently sitting at 19200. |
| `version = unknown` | The FC has **never received a UBX `MON-VER` reply** from the module. |
| `NOT CONFIGURED` | Auto-config never ran, because detection never completed. |
| `NOT CONNECTED` | `SENSOR_GPS` unset → and therefore no GPS elements in the OSD. |

### What "NOT CONNECTED" actually measures

From `cli.c`, the word is chosen purely from the GPS state machine — **not** from whether any data
has arrived:

```c
if (gpsData.state >= GPS_STATE_CONFIGURE) {
    cliPrint("connected, ");
} else {
    cliPrint("NOT CONNECTED, ");
}
```

The enum is **not** in the order the names suggest (`gps.h`):

```c
typedef enum {
    GPS_STATE_UNKNOWN = 0,
    GPS_STATE_DETECT_BAUD,        // 1
    GPS_STATE_INITIALIZED,        // 2
    GPS_STATE_CHANGE_BAUD,        // 3
    GPS_STATE_CONFIGURE,          // 4
    GPS_STATE_RECEIVING_DATA,     // 5
    GPS_STATE_PROCESS_DATA,       // 6
    GPS_STATE_LOST_COMMUNICATION, // 7
} gpsState_e;
```

`connected` requires state >= 4, so `NOT CONNECTED` means the driver is in `UNKNOWN`,
`DETECT_BAUD`, `INITIALIZED` or `CHANGE_BAUD`.

Note the dispatcher does **nothing** in two of those:

```c
switch (gpsData.state) {
case GPS_STATE_UNKNOWN:       // 0
case GPS_STATE_INITIALIZED:   // 2
    break;                    // <-- no handler runs

case GPS_STATE_DETECT_BAUD:   // 1
case GPS_STATE_CHANGE_BAUD:   // 3
case GPS_STATE_CONFIGURE:     // 4
    gpsConfigureHardware();
```

So a driver parked in `INITIALIZED` is stuck permanently and will never advance on its own.

This gives a very sharp test of which provider is actually live:

| Provider | Behaviour in `DETECT_BAUD` | What `status` shows with a silent module |
|---|---|---|
| `UBLOX` | Sends `MON-VER`, waits for a reply, cycles baud rates. Never advances without one. | `NOT CONNECTED` forever |
| `NMEA` | Advances to `CHANGE_BAUD` immediately, unconditionally. | **`connected`** within a couple of seconds |

On paper the NMEA path reaches `RECEIVING_DATA` in about 1.5 s regardless of whether the module
says anything. If `status` still reports `NOT CONNECTED` with `gps_provider = NMEA` confirmed by
`get gps_provider`, the driver is not running that path at all — it is parked in `UNKNOWN` or
`INITIALIZED`, which usually means the serial port was never opened. Read the exact state with
`debug_mode = GPS_CONNECTION` (below) rather than guessing.

Note the consequence: on NMEA, `connected` only means "the state machine advanced". It does **not**
prove data is arriving. `SENSOR_GPS` — and therefore the OSD elements — still requires a parsed
frame. Use the OSD elements appearing, or the Configurator GPS tab, as the real proof of data.

### Why the baud rate is a red herring

The UBLOX baud-detect loop in `gps.c` cycles **downward** through this table:

```c
static const gpsInitData_t gpsInitData[] = {
    { BAUD_230400, ... },
    { BAUD_115200, ... },
    { BAUD_57600,  ... },
    { BAUD_38400,  ... },
    { BAUD_19200,  ... },
    { BAUD_9600,   ... }
};
```

Starting from the configured rate (57600, index 2) and decrementing, by the time it reached 19200
it had **already tried 115200 and failed**. So simply setting the port to 115200 will not fix this.

### Why UBLOX mode needs a bidirectional connection

This is the crux. In `GPS_STATE_DETECT_BAUD`, Betaflight does not passively listen — it **transmits**:

```c
// Send MON-VER messages at GPS_CONFIG_BAUD_CHANGE_INTERVAL for GPS_BAUDRATE_TEST_COUNT times
if (messageCounter < GPS_BAUDRATE_TEST_COUNT) {
    if (!messageSent) {
        gpsData.platformVersion = UBX_VERSION_UNDEF;
        ubloxSendClassMessage(CLASS_MON, MSG_MON_VER, 0);
        ...
```

and it only escapes that state when a version reply comes back:

```c
if (gpsData.platformVersion > UBX_VERSION_UNDEF) {
    ...
    gpsSetState(GPS_STATE_CHANGE_BAUD);
    return;
}
```

**With `gps_provider = UBLOX`, the FC's TX1 (PA9) must be wired to the GPS module's RX pad.**
A three-wire install (5V, GND, GPS-TX → FC-RX) can never leave baud detection, no matter what
baud rate you set. Symptom: exactly the `version = unknown` / `NOT CONFIGURED` loop above.

The NMEA path has no such requirement — it skips detection entirely:

```c
case GPS_STATE_DETECT_BAUD:
    // no attempt to read the baud rate of the GPS module, or change it
    gpsSetState(GPS_STATE_CHANGE_BAUD);
    break;
```

---

## RESOLVED: the hardware is fine — `gpspassthrough` evidence

Captured 2026-09-01 at 115200:

```
$GNRMC,151946.90,V,,,,,,,010926,,,N,V*12
$GNGGA,151946.90,,,,,0,00,99.99,,,,,,*7F
$GNGSA,A,1,,,,,,,,,,,,,99.99,99.99,99.99,1*33
$GPGSV,1,1,04,05,,,28,21,,,32,23,,,31,24,,,17,1*6E
$GAGSV,1,1,00,0*74
µb\ê    /óÿÿÿÿ.Éþÿ¤½ÿÿÿÿÿÿvß N¨'\@V/-9
```

### What this proves

| Observation | Conclusion |
|---|---|
| Sentences are **readable** at 115200 | Baud is correct. 115200 confirmed, 9600 theory dead. |
| Valid checksums, 10 Hz cadence | Module is healthy and transmitting continuously. |
| Data reaches the FC's UART | Wiring, connector, crimp, solder joints and PA10 are all **good**. |
| `µb` = `0xB5 0x62` | UBX sync chars — the module emits **UBX and NMEA simultaneously**. |

Every hardware hypothesis in this document — swapped wires, bad crimp, solder bridge, wrong baud,
dead module, missing 5V — is **disproven**. The physical install is correct.

### Current satellite state: cold start, no fix

```
$GNGGA,...,0,00,99.99,...     fix quality 0, 00 satellites used, HDOP 99.99
$GNRMC,...,V,...              V = Void, no valid position
$GNGSA,A,1,...                mode 1 = no fix (2 = 2D, 3 = 3D)
$GPGSV,1,1,04,05,,,28,...     4 GPS satellites in view, SNR 28/32/31/17
```

Signal strength is fine (SNR in the high 20s / low 30s is usable). But the GSV elevation and
azimuth fields are **empty**, which means the module has no almanac or ephemeris yet. This is a
true cold start: it must download ephemeris from the satellites themselves, which needs several
minutes of uninterrupted clear sky. Indoors or on a balcony it may never complete.

Once the first fix lands, the module retains almanac data and subsequent fixes are much faster.

### Why Betaflight still showed nothing

Betaflight's NMEA parser accepts these sentences. It matches on `&string[2]`, so the multi-GNSS
`$GN...` talker ID is handled identically to `$GP...`:

```c
if (strcmp(&string[2], "GGA") == 0) {
    gps_frame = FRAME_GGA;
```

and a GGA frame returns `true` **regardless of fix** — the fix check only gates copying the
coordinates, not the return value:

```c
case FRAME_GGA:
    if (STATE(GPS_FIX)) {
        sol->llh.lat = data->latitude;
        ...
    }
    ...
    return true;   // <-- unconditional
```

So on `gps_provider = NMEA` at 115200 this stream sets `SENSOR_GPS` and the OSD elements appear
within seconds, showing zeros until a fix arrives.

**Therefore the empty OSD means the quad was not actually running the NMEA config at the time** —
on UBLOX the driver never leaves `DETECT_BAUD`, so `gpsHandleFrameComplete()` never reaches its
`state == GPS_STATE_RECEIVING_DATA` guard and `SENSOR_GPS` is never set, no matter how good the
incoming data is.

### Ruling out the LED strip / DMA interaction

The LED strip on this quad is remapped to `A03` (PA3) with an explicit DMA claim:

```
resource LED_STRIP 1 A03
timer A03 AF2          # TIM5 CH4
dma pin A03 0          # DMA1 Channel 1
```

A reasonable worry is that this collides with UART1 and deafens the GPS. It does not, and the
`gpspassthrough` capture already proves it:

**Pin, timer and DMA claims are made at boot from the saved configuration — not from whether the
hardware is physically attached.** An unplugged LED strip changes nothing; the driver still owns
DMA1 Channel 1 as long as those lines are in the config. Since NMEA sentences flowed through UART1
during passthrough with that claim active, there is no conflict.

Confirmed on hardware 2026-09-01:

```
DMA1 Channel 1: LED_STRIP
DMA1 Channel 2: DSHOT_BITBANG 2
DMA1 Channel 3: SPI_SDO 1        DMA1 Channel 4: SPI_SDI 1
DMA1 Channel 5: SPI_SDO 3        DMA1 Channel 6: SPI_SDI 3
DMA1 Channel 7: ADC 1            DMA1 Channel 8: ADC 2
DMA2 Channel 1-8: FREE
```

**No UART appears in the DMA table at all.** Serial on this board is interrupt-driven, not
DMA-driven, so `LED_STRIP` owning DMA1 Channel 1 cannot starve UART1 under any circumstances.
DMA2 is entirely unused. The conflict theory is dead.

`resource show` confirms the pin map is exactly right:

```
A03: LED_STRIP        (remapped, as intended)
A02: FREE             (UART2 TX released)
A09: SERIAL_TX 1      (GPS TX -> module RX)
A10: SERIAL_RX 1      (GPS RX <- module TX)
B02: FREE             (target's default LED pin, correctly released)
B10/B11: SERIAL_TX/RX 3   (ELRS)
C10/C11: SERIAL_TX/RX 4   (DJI O4)
```

Nothing is stolen, nothing is double-claimed, and UART1 owns both of its pins.

If you ever want to test by elimination, `resource LED_STRIP 1 NONE` then `save` frees it — but
**restore it afterwards** with `resource LED_STRIP 1 A03` plus the `timer` and `dma` lines above,
or the strip will stay dark.

### Why UBLOX cannot be used here

The module emits UBX, so the parser would cope. The blocker is the handshake: `DETECT_BAUD` waits
for a `MON-VER` reply, and this module never answers one. Either it does not accept UBX on its
input port, or the FC to module direction is not delivering. Since NMEA is fully sufficient, this
is not worth pursuing.

---

## Signal corruption once the DJI O4 is connected

Second `gpspassthrough` capture, 2026-09-01, **with the O4 air unit connected** — same 115200,
same module, same wiring:

```
ðþþþþþþþþþþþþþþþþþþr"Àâþ...
$GMV,!,1,3      (was $GPGSV,1,1,3...)
$GNT,@$1        (was $GNGGA,...)
$GPGS)          (was $GPGSV)
$GNGª1A,!,00    (was $GNGSA,A,1,00)
```

### Reading it

NMEA structure is still recognisable — sentence starts, comma counts and field shapes survive —
so the module is transmitting normally at the correct baud. Individual **bits** are being flipped
in transit. The long runs of `0xFE` / `0xF0` are what a UART produces from a line that is glitching
while idle.

This is a **signal-integrity fault, not a configuration fault**. No Betaflight setting will fix it,
and lowering `gps_baud` on the FC alone will make it worse, because the module keeps transmitting
at 115200 regardless — both ends must match.

Every checksum fails, so Betaflight's NMEA parser discards every sentence, `SENSOR_GPS` is never
set, and the OSD stays empty. Identical symptom to the earlier problem, completely different cause.

### The A/B test that isolates it

The clean capture was taken with the quad **disassembled and the O4 disconnected**. The corrupt one
with the O4 **connected**. Two candidates, and one test separates them:

**Unplug the O4, leave everything else exactly as it is now, re-run `gpspassthrough`.**

**Result 2026-09-01: disconnecting the O4 restored clean NMEA in passthrough.** Treat this as
provisional rather than conclusive — see the passthrough caution above. The comparison also varied
the interrupt load on the forwarding loop itself, so it does not cleanly isolate line corruption.
The wiring is sound either way; if there is a real fault it is interference or power, not a broken
strand.

Note also that `status` reports `GPS: connected` **with the air unit attached** (runs 1 and 2,
2026-09-01), which is consistent with the driver reaching `RECEIVING_DATA` normally.

**Follow-up: moving the GPS module 15 cm from the air unit did not help.** Note this does *not*
exclude radiated pickup — the leads still run from the module back to the flight controller,
passing the air unit and its cable on the way. Relocating the module while leaving the wiring
routed as before tests very little. The leads are the more likely antenna, being longer than the
module and running the length of the airframe.

### The LED strip is not a contributor

Reconnecting the 14-LED strip with the O4 still unplugged leaves the GPS working cleanly. The strip
is ruled out.

**It says nothing about the 5 V rail, however.** Inspection of the board shows how the strip is
actually wired:

| Wire | Soldered to |
|---|---|
| Yellow (data) | **R2** pad — PA3, matching `resource LED_STRIP 1 A03` |
| Red / black | **directly to the battery input wires** — VBAT, not the 5 V BEC |

So the strip is powered from pack voltage and never loads the 5 V regulator. An earlier version of
this document argued that the strip proved the 5 V rail tolerates ~800 mA of bursty switching load
without disturbing UART1. **That reasoning was wrong** — the load was never on that rail. The LED
test is a valid control for the *data* pin and for RF from the strip, and nothing more.

What still stands: the measured **5.070 V** at the module shows correct rail *level*. What is still
untested is rail behaviour under the O4's load, and the ground return.

Note also that BetaFPV's own layout puts the LED data line on **TX2**, while this quad has it on
**R2 (RX2)**. Either way UART2 is consumed and GPS has to live on UART1, which is fine on the ELRS
build.

### ROOT CAUSE (confirmed): the O4's SBUS output shares PA10 with the GPS

Not interference at all — **bus contention.** Two outputs driving one net.

The evidence lines up exactly:

1. The Betaflight target for this board selects the receiver UART at compile time:

   ```c
   #ifdef USE_SERIALRX_SBUS
   #define SERIALRX_UART       SERIAL_PORT_USART1     // RX1 = PA10
   #else
   #define SERIALRX_UART       SERIAL_PORT_USART3
   #define SERIALRX_PROVIDER   SERIALRX_CRSF
   #endif
   ```

   The SBUS build expects the receiver on **UART1 RX = PA10**.

2. BetaFPV's 2025.12.5 changelog states plainly: *"Fixed serial-port conflicts among GPS, RGB and
   SBUS: GPS uses independent UART2, RGB control wire connects to TX1, **SBUS is assigned to RX1**"*.
   They are documenting a real, known conflict on this board.

3. The DJI O4 air unit emits **SBUS on its connector**, and the board's 6-pin HD VTX connector
   routes that pin to **RX1 (PA10)** — which is where this quad's GPS module TX wire is soldered.

So whenever the air unit is plugged in, the O4's SBUS output and the GPS module's TX output are
both driving PA10. Two push-pull drivers on one line. The UART sees whichever wins each edge.

**This explains every observation better than RF does:**

| Observation | Explained by contention? |
|---|---|
| Clean NMEA with the O4 unplugged | Yes — only one driver on the net |
| Garbage the instant the O4 is connected | Yes — second driver joins |
| Moving the module 15 cm changed nothing | Yes — it is not radiated, distance is irrelevant |
| Corruption is bit-level, with NMEA fragments surviving | Yes — SBUS at 100 kbaud chopping into 115200 NMEA |
| 5 V measured healthy at 5.070 V | Yes — the supply was never the issue |
| LED strip causes no trouble | Yes — different pin entirely |

### Confirmed on hardware, 2026-09-01

BetaFPV use an all-black 6-pin connector for the air unit, so the DJI wire-colour convention does
not apply. Sweeping all six socket pins against **R1** with the battery disconnected: **an end pin
beeps.** The air unit connector is routed to PA10 on the PCB.

That closes the diagnosis. The GPS module's TX and the O4's SBUS output are wired to the same net,
and the corruption is bus contention between two drivers — not RF, not power, not grounding, and
not anything that could be fixed in software.

Sanity check, also confirmed: that pin does **not** beep against GND, so it is a true signal line
and not a misread ground. The **second** pin does beep against GND — a signal sitting next to its
own return, exactly the arrangement expected. R1 is not shorted to ground; it is bonded to a live
driver on the air unit.

### Why this fits everything

This is the only hypothesis in this document that explains the full set of observations without
special pleading:

- Clean NMEA with the O4 unplugged, garbage the moment it is connected — one driver versus two
- Moving the module 15 cm changed nothing — the fault is a shared copper net, so distance is irrelevant
- Corruption is bit-level with NMEA fragments surviving — SBUS at 100 kbaud cutting into 115200 NMEA
- 5 V measured at a healthy 5.070 V — the supply was never involved
- The LED strip causes no trouble — different pin entirely
- BetaFPV shipped a firmware release specifically to reorganise GPS, RGB and SBUS on this board

The fix is mechanical: move the GPS off UART1. This also frees RX1 for its intended purpose, making
the DJI Remote Controller 3 usable — the same rewire solves both.

### Narrowing it further: radiated or conducted?

The fixes differ, so spend five minutes separating the two.

**Test 1 — move the module, keep it powered.** With the O4 connected and running, lift the GPS
module well away from the airframe on temporary extended leads and re-run `gpspassthrough`.

| Result | Mechanism |
|---|---|
| Clean | **Radiated.** RF from the air unit is coupling into the module or its leads. Fix by distance, routing and shielding. |
| Still corrupt | **Conducted.** Noise is arriving through the 5V rail or the ground return. Fix by decoupling and grounding. |

**Test 2 — drop the VTX power.** Set the O4 to its lowest output (25 mW) from the Betaflight
Video Transmitter tab or the goggles. If the corruption eases or clears, that confirms radiated RF.
Never run the air unit without its antenna attached to test this — that risks damaging it.

**Test 3 — measure the rail.** DC volts at the GPS module's 5V pad with the O4 powered and
transmitting. Meaningful sag below ~4.8 V points at conducted/supply trouble.

### Supply measured good — but that does not clear conducted noise

Measured 2026-09-01: **5.070 V at the GPS module.** Healthy, no sag. Combined with the LED strip
result, the 5 V rail is demonstrably solid.

Two limits on what that measurement can tell you, both worth understanding before ruling anything out:

1. **It is measured against the same ground it cannot vet.** A multimeter reads 5 V *relative to
   local GND*. If the ground return itself is bouncing — high current from the air unit through a
   shared return path — the reading stays a perfect 5.070 V while the UART's voltage reference
   moves underneath it. Ground-offset noise is invisible to this test by construction.
2. **A DC meter averages.** Switching ripple in the tens-to-hundreds of kHz, or RF, does not show
   up as a DC deflection. Seeing it needs an oscilloscope.

So supply *level* is cleared. Ground integrity and RF are not.

### 3S operation

This quad is flown on 3S, which the 2-4S board supports and which has been flight-tested. It is not
a factor in the GPS fault. One consequence worth remembering: `auto_profile_cell_count` selects
**profile 1** (the "3S" tune) on a 3S pack, not profile 0.

Minor note for later: the 9 V BEC feeding the O4 has less headroom on 3S than on 4S. Near the end
of a pack — around 3.3 V/cell, roughly 9.9 V — a 9 V regulator is running close to dropout. That is
not the cause of corruption on a freshly charged pack, but it is worth keeping in mind if the fault
ever turns out to worsen as the battery drains.

### Fixes for radiated pickup

- **Distance and orientation first.** Move the GPS module as far from the air unit and its
  antennas as the frame allows — top of the canopy, ceramic patch facing up. On a 2.2" cinewhoop
  this is the single most effective change available.
- **Shorten the GPS leads and twist them.** Twisting TX, RX and GND together dramatically reduces
  loop area and common-mode pickup. Excess length coiled up next to a VTX is an antenna.
- **Cross, do not run parallel.** Where GPS leads must pass the air unit's cabling, cross at 90
  degrees rather than running alongside.
- **Ferrite bead** over the GPS cable close to the flight controller.
- **Copper tape shield**, grounded at one end only, between the air unit and the GPS leads. One
  end only — grounding both ends creates a loop that can make things worse.

### Fixes for conducted noise

- **Decouple at the module.** A 10-47 uF electrolytic in parallel with a 100 nF ceramic across the
  GPS 5V and GND, physically close to the module, is the standard fix.
- **Improve the ground return.** Run GPS GND to a solid ground pad rather than daisy-chaining it
  through a path shared with the air unit's current draw. A shared high-current return shifts the
  UART's voltage reference and corrupts bits directly.
- **Check the 5V BEC headroom.** The Cube board feeds 9V to the O4 and 5V to accessories. If the
  5V rail is already loaded, the GPS module is the thing that suffers first.

### Note on the earlier "no fix" state

The clean capture showed `fix quality 0`, `00` satellites used and empty GSV elevation/azimuth —
a genuine cold start needing several minutes of open sky. That is expected and separate from the
corruption above. Fix the signal integrity first, then allow proper time outdoors for the first fix.

---

## Current working configuration

As of 2026-09-01 the GPS reaches `RECEIVING_DATA` with this setup:

```
serial UART1 2 115200 115200 0 115200
set gps_provider = NMEA
set gps_auto_baud = OFF
set gps_auto_config = OFF
```

`status` reports:

```
GPS: connected, UART1 115200 (set to 115200), auto config OFF, version =  unknown
```

### `version = unknown` is expected on NMEA — do not chase it

That field is `gpsData.platformVersion`, which is only ever populated by parsing a UBX `MON-VER`
reply. The NMEA driver never sends `MON-VER` and never sets it. On NMEA it stays `unknown`
permanently even when the module is working perfectly. It is only meaningful on the UBLOX provider,
where `unknown` does indicate a failed handshake.

### What actually changed

The provider, not the location. With `gps_provider = UBLOX` and a fixed baud, the driver sits in
`DETECT_BAUD` forever waiting for a `MON-VER` reply. Switching to NMEA lets it skip detection and
advance. Standing on the balcony affects satellite reception, not the serial state machine.

### `connected` still is not proof of data

Remember the state machine advances to `RECEIVING_DATA` on the NMEA path whether or not the module
says anything. The real confirmation is `SENSOR_GPS`, which needs a parsed frame:

- **GPS elements appear in the OSD** (zeros with no fix, real values with one), or
- the Configurator **GPS** tab shows a satellite count.

---

## UBLOX: tested, does not work on this quad — running NMEA

NMEA works, which proves the module transmits and the GPS-TX -> FC-RX1 wire is good. What is still
unknown is whether **FC TX1 (PA9) -> GPS RX** is connected. UBLOX mode needs it, and buys you
auto-configuration, a 10 Hz nav rate, Galileo and the airborne nav model. On NMEA,
`gps_update_rate_hz`, `gps_ublox_use_galileo` and `gps_sbas_mode` do nothing — Betaflight cannot
configure the module.

**Tested 2026-09-01: switching to UBLOX drops back to `NOT CONNECTED`.** NMEA works, UBLOX does not.

### What that does and does not prove

All four wires are connected: **5V, GND, GPS-TX -> FC-RX1, GPS-RX <- FC-TX1.**

NMEA working proves the **receive** direction is good — the module transmits and PA10 hears it.
UBLOX failing means the `MON-VER` handshake never completes, which needs the **transmit**
direction. So the fault is somewhere on FC-TX1 -> module-RX, and there are two candidates:

1. **The wire is not landing where it should.** A cold joint on the TX1 pad, or the wire on a
   different pad than PA9. Only the receive path is exercised by NMEA, so a bad TX joint is
   invisible until you try UBLOX.
2. **The module ignores UBX input.** u-blox receivers have a per-port input-protocol setting
   (`CFG-UART1INPROT-UBX`). A module shipped configured for NMEA-only input will silently discard
   `MON-VER` no matter how good the wiring is. Rebadged M10 modules are not always factory-set to
   accept UBX.

### How to tell them apart

- **Multimeter, continuity:** BZ-181 `RX` pad to the FC `TX1` pad. Open circuit = candidate 1,
  and it is a resolder. This is the quick one, do it first.
- **u-center through `gpspassthrough`:** run `gpspassthrough` in the CLI, then point u-blox u-center
  at the same COM port at 115200. If u-center can poll the module and read its configuration, the
  UBX input path works end to end and you are looking at candidate 2 — in which case you can enable
  `CFG-UART1INPROT-UBX` from u-center and UBLOX mode will then work.

### None of this is required

NMEA gives you position, satellites, speed, altitude, home distance and direction — everything the
OSD and lost-model telemetry need. Chasing UBLOX buys the 10 Hz nav rate, Galileo, auto-config and
the airborne nav model. Worth doing if you want it; not worth desoldering the build over.

For reference, the settings that were tried and rejected:

```
set gps_provider = UBLOX
set gps_auto_config = ON
set gps_auto_baud = ON
set gps_ublox_use_galileo = ON
set gps_sbas_mode = AUTO
set gps_update_rate_hz = 10
save
```

Result: `NOT CONNECTED`. Reverted to NMEA.

### Settings that do nothing while on NMEA

Because Betaflight is not configuring the module, these have no effect and should not be relied
on — the BZ-181 runs at its power-on defaults:

- `gps_update_rate_hz`
- `gps_ublox_use_galileo`
- `gps_sbas_mode`
- `gps_auto_config`
- `gps_auto_baud` (the NMEA path skips baud detection entirely)

---

## Fix — work through in order

### Step 1: prove the module is transmitting (NMEA, fixed baud)

This bypasses baud detection completely, so it works even on a three-wire install.

```
serial UART1 2 115200 115200 0 115200
set gps_provider = NMEA
set gps_auto_baud = OFF
set gps_auto_config = OFF
save
```

Power cycle **on a battery**, wait ~15 s, then run `status`.

- **`GPS: ... CONNECTED`** → the module is alive and transmitting. Go to Step 2.
- **Still `NOT CONNECTED`** → try `9600` in place of the second `115200` (some BZGNSS units ship
  at 9600 rather than the documented 115200). If neither works, go to Step 3.

Once connected, the OSD GPS elements will appear immediately — showing zeros indoors, which is
the correct no-fix behaviour.

### Step 2: restore UBLOX mode (only if TX is wired)

NMEA at a fixed rate works, but you lose 10 Hz updates, Galileo and auto-config. To get them back
you need the fourth wire — **FC TX1 (PA9) → GPS module RX**:

```
serial UART1 2 115200 115200 0 115200
set gps_provider = UBLOX
set gps_auto_config = ON
set gps_auto_baud = ON
set gps_ublox_use_galileo = ON
set gps_sbas_mode = AUTO
set gps_update_rate_hz = 10
save
```

`status` should then report a real version string instead of `unknown`.

If you do not want to add that wire, staying on NMEA is a perfectly reasonable outcome — you still
get position, sats, speed, home distance and the OSD elements. You just lose auto-configuration.

### Reading the exact state — `debug_mode = GPS_CONNECTION`

```
set debug_mode = GPS_CONNECTION
save
```

Betaflight Configurator -> **Sensors** tab -> enable **Debug**. Read **debug[4]**, which the driver
sets to `state * 100 + state_position`:

| debug[4] | State | Meaning |
|---|---|---|
| `0xx` | UNKNOWN | Port never opened. Serial allocation or resource problem, not wiring. |
| `1xx` | DETECT_BAUD | UBLOX baud hunt — sending `MON-VER`, nothing replying. |
| `2xx` | INITIALIZED | **Stuck** — no handler runs in this state. |
| `3xx` | CHANGE_BAUD | Mid handover, should pass through in ~1 s. |
| `4xx` | CONFIGURE | Talking to the module, applying config. |
| `5xx` | RECEIVING_DATA | Working. `SENSOR_GPS` will set on the next parsed frame. |
| `7xx` | LOST_COMMUNICATION | Was working, went quiet. Intermittent wiring or power. |

Other slots: debug[2] = time since last nav data, debug[3] = detect baud / 100.

Set `debug_mode` back to `GYRO_FILTERED` when finished.

### NMEA does not auto-detect baud — sweep it manually

`gps_auto_baud` only applies to the UBLOX provider. On NMEA the rate in the serial line is used
as-is, and a mismatch produces a stream of garbage that the NMEA parser silently discards: state
reaches `RECEIVING_DATA`, `status` says `connected`, and `SENSOR_GPS` never sets. Exactly the
symptom of an empty GPS OSD.

The BZ-181 is documented at 115200, but rebadged modules are not always shipped that way. Work
through the rates, checking the OSD or the Configurator GPS tab after each `save`:

```
serial UART1 2 115200 9600 0 115200
save
```

then in turn `19200`, `38400`, `57600`, `115200`, `230400` in that fourth field. The moment the
rate matches, the GPS elements appear on their own.

### WARNING: `gpspassthrough` halts the flight controller

`serialPassthrough()` in `serial.c` runs an unbounded loop:

```c
void serialPassthrough(serialPort_t *left, serialPort_t *right, ...)
{
    ...
    while (1) {
```

The scheduler stops entirely for as long as passthrough is active. Three consequences look alarming
but are completely normal:

| Symptom | Cause |
|---|---|
| Radio announces **"Sensor lost"** | Telemetry stopped — see below, this happens in the plain CLI too |
| Configurator drops to the **Welcome screen** | MSP is no longer answering — the port is now a raw bridge |
| Only a power cycle recovers it | The loop never exits on USB; a reboot is the documented way out |

None of these indicate a crash, a brownout or a hardware fault. **Do not use `gpspassthrough` as a
routine test.** It is for one question only: are bytes arriving, and are they intact.

### "Sensor lost" is caused by the CLI, not by anything on the aircraft

Betaflight skips the telemetry task entirely whenever the CLI is open (`fc/tasks.c`):

```c
static void taskTelemetry(timeUs_t currentTimeUs)
{
    if (!cliMode && featureIsEnabled(FEATURE_TELEMETRY)) {
        subTaskTelemetryPollSensors(currentTimeUs);
        telemetryProcess(currentTimeUs);
    }
}
```

So CRSF telemetry stops the moment you enter the CLI, and the radio announces "Sensor lost". This
happens after a plain `status` command — no passthrough required.

Confirmed empirically 2026-09-01: three consecutive runs, two with the air unit connected and one
without, all produced "Sensor lost" after `status`. **It is not a fault, and it is not related to
the O4.**

### PROVEN: `GPS: connected` is meaningless on the NMEA provider

Control test, 2026-09-01, run #4 — **GPS module physically unplugged**:

```
GPS: connected, UART1 115200 (set to 115200), auto config OFF, version =  unknown
```

With no module attached at all, `status` still reports `connected`. This confirms on hardware what
the source predicted: `cli.c` derives that word solely from `gpsData.state >= GPS_STATE_CONFIGURE`,
and the NMEA path advances the state machine unconditionally, without ever needing a byte.

**Consequence: every `GPS: connected` reading in this document is worthless as evidence of a
working GPS.** Do not use the `status` GPS line to judge whether the module is working, on this or
any other NMEA build.

The only valid indicators are the ones that depend on `SENSOR_GPS`, which requires a parsed frame:

| Test | Valid? |
|---|---|
| `status` says `GPS: connected` | **No** — true with the module unplugged |
| Configurator **GPS** tab shows a satellite count | **Yes** |
| GPS elements visible in the OSD | **Yes** |
| `gpspassthrough` shows readable NMEA | Yes, but stops the scheduler and is unfair with the O4 attached |

Run #4 also produced "Sensor lost" with the GPS unplugged, further confirming that message comes
from the CLI disabling the telemetry task and nothing else.

### Caution: `gpspassthrough` is not a fair test with the O4 connected

With passthrough running, the scheduler is stopped but **UART4 interrupts from the O4's MSP
DisplayPort traffic keep firing**. That interrupt load can starve the passthrough bridge's servicing
of UART1 and garble the forwarded stream — corruption introduced by the measurement rather than
present on the wire.

This weakens the earlier "the O4 is conclusively the cause" conclusion. It was drawn from clean
passthrough with the O4 unplugged versus garbled passthrough with it connected — a comparison that
also changes the interrupt load on the very loop doing the forwarding.

**Re-establish it with a test that does not stop the scheduler:** the Configurator GPS tab, with the
O4 connected. A live satellite count there means `SENSOR_GPS` is set and frames are parsing
normally, whatever passthrough showed.

For ongoing checks with the aircraft in normal operation, use instead:

- `status` — is `GPS: connected`
- Configurator **GPS** tab — live satellite count, updates without stopping the FC
- The GPS elements in the goggles

### Is the module transmitting at all? — `gpspassthrough`

The single most decisive test, and independent of every driver detail above:

```
gpspassthrough
```

This bridges the CLI straight to the GPS UART. With the port at 115200 and the module in its
default NMEA mode you should see readable sentences scrolling:

```
$GNGGA,...
$GNRMC,...
```

| What you see | Conclusion |
|---|---|
| Readable `$GN...` / `$GP...` sentences | Module is alive, powered and correctly wired to RX1. The fault is in Betaflight config. |
| Garbage / random bytes | Data is arriving but the baud is wrong. Try 9600. |
| **Nothing at all** | No data on RX1. Power, wiring or a dead module. |

Reboot the FC to exit passthrough.

### Step 3: nothing works — it is wiring or power

- **GPS module TX → FC RX1 (PA10).** Swapped or missing is the most common cause.
- **5V, not 3.3V.** Measure at the module itself, on battery power, not USB.
- Reflow the RX1 joint — a cold joint gives exactly this symptom.
- Confirm with `gpspassthrough` (it exists in the CLI: `gpspassthrough` — "passthrough gps to
  serial"). Any stream of characters, even garbage, proves the module is transmitting. Nothing at
  all means it is dead or unpowered. Reboot to exit passthrough.

---

## About the Lua script showing position correctly

That is genuine evidence GPS *has* worked — Betaflight only populates the CRSF GPS telemetry frame
from its own parsed GPS data, so a correct position on the radio means the whole chain worked at
that moment.

Two things to rule out:

1. **Was that reading from this quad, or the FireFly?** Both send GPS telemetry over CRSF and the
   Lua does not care which model it came from.
2. **Does the radio have its own GPS?** Some lost-model scripts fall back to the *radio's* last
   known position rather than the craft's. If so, a correct reading says nothing about the drone.

If the Lua genuinely showed this quad's position, the wiring is fine and the fault is intermittent —
which points at the baud mismatch above (auto-baud sometimes locking on, sometimes not) rather than
a hardware problem.

---

## Related settings already on this quad

```
set mag_hardware = NONE            # no compass — Betaflight does not need one for GPS
set gps_set_home_point_once = ON   # home set on first fix, kept across arms
```

`gps_set_home_point_once = ON` means home is **not** re-set between arms. If you fly several packs
from different spots, home distance and direction will keep pointing at the first location of the
session. Set it to `OFF` if you would rather home follow each arm.

## GPS Rescue on this airframe

Available, but think carefully. A 2.2" ducted cinewhoop carrying an O4 Pro has limited thrust
margin, poor glide and short endurance. On this class of quad GPS Rescue is far more useful as a
*"where did it land"* beacon than as a genuine return-to-home. Reliable telemetry and a good
home-distance readout in the OSD is the higher-value outcome.
