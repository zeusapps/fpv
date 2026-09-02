# Binding the HelloRadio V12 MAX to the Pavo20 Pro II (ELRS)

Applies to the ExpressLRS version of the Pavo20 Pro II (integrated ELRS receiver on the AIO board).
If you bought the **DJI SBUS** version, this guide does not apply — see the note at the bottom.

## Prerequisites

- The V12 MAX's internal ELRS module and the Pavo20's receiver must be on **matching major
  firmware versions**. The Pavo20 Pro II ships with **ELRS 3.5.6**, so your radio module needs
  to be on 3.x as well. A 3.x radio will not talk to a 2.x receiver.
- USB cable ready to verify in Betaflight Configurator.
- Props off for everything below.

## Method 1: Binding phrase (recommended)

A binding phrase makes TX and RX pair automatically every time — no bind button dance.
Both ends must be flashed with the **same phrase**.

### On the HelloRadio V12 MAX

1. Power on the radio.
2. Open the **ExpressLRS Lua script** (SYS / Tools menu → ExpressLRS).
3. Select **WiFi Connectivity** → **Enable WiFi** on the TX module.
4. Connect to the module's WiFi hotspot from your phone or laptop (default password is usually
   `expresslrs`), then open `http://10.0.0.1` in a browser.
5. Set your **Binding Phrase** — anything unique to you, used identically on every quad.
6. Save. The module reboots.

### On the Pavo20 Pro II receiver

1. Power the drone on battery (props off, do not arm).
2. Leave the radio **off**. After ~60 seconds with no TX connection the receiver starts its own
   WiFi hotspot and the LED pattern changes.
3. Connect to the receiver's WiFi, open `http://10.0.0.1`.
4. Set the **same binding phrase**.
5. Save. The receiver reboots and should auto-connect once you turn the radio back on.

## Method 2: Traditional bind mode

### Put the receiver into bind mode — pick one

**Option A — Betaflight CLI (easiest):**
1. Connect via USB, open Betaflight Configurator → **CLI** tab.
2. Type `bind_rx` and press Enter.
3. Receiver LED starts a quick double-blink.

**Option B — Power cycle:**
1. Power the drone on for ~2 seconds, then off. Repeat 3 times.
2. After the third power-on the LED should quick double-blink.

### Bind from the radio

1. Open the **ExpressLRS Lua script** on the V12 MAX.
2. Select **Bind**.
3. Wait until the receiver LED goes **solid** — bound.
4. Power cycle the drone to confirm it reconnects on its own.

## Verifying

1. In the ELRS Lua script, a **"C"** in the top-right corner means the link is up.
2. Connect the drone via USB → Betaflight **Receiver** tab.
3. Move sticks and switches — the channel bars should respond.
4. Confirm the channel map is **AETR** (the ELRS default, and the V12 MAX default).
5. Confirm `serialrx_provider = CRSF` in the CLI.

## Recommended ELRS packet rate

For a cinewhoop flown close in, you do not need the highest rate. **250Hz** gives a good balance
of latency and range/penetration. 500Hz is fine too. Set it in the Lua script under **Packet Rate**.

Set **Telemetry Ratio** to `Std` (1:64) or `1:32` — you want telemetry for the link stats in the OSD.

## Switch layout used by these configs

This matches the layout already used on your Meteor75, so muscle memory carries over:

| Switch | Channel | Position | Function |
|---|---|---|---|
| AUX1 / CH5 | ch 0 | high (1700-2100) | **ARM** |
| AUX2 / CH6 | ch 1 | low (900-1300) | **ANGLE** |
| AUX2 / CH6 | ch 1 | mid | ACRO (no mode active) |
| AUX2 / CH6 | ch 1 | high (1650-2100) | **TURTLE** |
| AUX3 / CH7 | ch 2 | high (1700-2100) | **PREARM** |
| AUX4 / CH8 | ch 3 | high (1700-2100) | **BEEPER** |
| AUX5 / CH9 | ch 4 | high (1700-2100) | **LEDLOW** (LED strip off) |
| AUX5 / CH9 | ch 4 | low / mid | **rate profile select** (via `adjrange`) |

CLI form, as flashed:

```
aux 0 0 0 1700 2100 0 0    # ARM
aux 1 1 1 900 1300 0 0     # ANGLE
aux 2 13 3 1700 2100 0 0   # BEEPER
aux 3 15 4 1700 2100 0 0   # LEDLOW
aux 4 35 1 1650 2100 0 0   # TURTLE
aux 5 36 2 1700 2100 0 0   # PREARM

adjrange 0 0 4 900 1250 12 4 0 0    # AUX5 low  -> rate profile
adjrange 1 0 4 1300 1700 12 4 0 0   # AUX5 mid  -> rate profile
```

Note AUX3 is PREARM — the quad will not arm unless PREARM is high **and** AUX1 is high.
That is a deliberate two-step safety, not a fault.

## Troubleshooting

- **No response in Receiver tab:** check Serial RX is enabled on the receiver's UART in the Ports
  tab and that `serialrx_provider = CRSF`.
- **Sticks move the wrong channels:** channel map mismatch — both ends must expect AETR.
- **Receiver WiFi doesn't appear:** it only starts after ~60s with no TX connection. Turn the radio off.
- **Bind fails entirely:** major version mismatch. Check both ends are 3.x.
- **Bound but won't arm:** almost always PREARM (AUX3) not set, or the arming-disabled flags in the
  OSD / `status` in CLI. Type `status` in the CLI and read the `Arming disable flags`.

## If you have the DJI SBUS version instead

There is no ELRS receiver to bind. You bind the DJI controller to the O4 air unit through the goggles
/ controller linking procedure, and Betaflight needs `serialrx_provider = SBUS` with SERIAL_RX on the
air unit's SBUS UART. The AUX layout above still applies, but it is configured on the DJI controller.

---

# Switching between ELRS and the DJI Remote Controller 3 (SBUS)

**No reflash is required.** The firmware on this quad has both protocols compiled in — the build
key's option list includes `USE_SERIALRX_CRSF` and `USE_SERIALRX_SBUS`. The `SERIALRX_UART` and
`SERIALRX_PROVIDER` defines in the Betaflight target only set what a `defaults` reset restores;
they do not restrict what the firmware can do at runtime.

BetaFPV publish separate ELRS and SBUS images purely so the quad works out of the box without the
customer configuring anything. Switching is two settings:

1. Which UART carries **Serial RX**
2. `serialrx_provider`

Both receivers are physically present at all times — the onboard ELRS module on UART3, and the
O4 air unit's SBUS output on RX1. Switching just selects which one Betaflight listens to.

## Prerequisite: GPS must not be on UART1

SBUS arrives on **RX1 (PA10)**. If the GPS module's TX is still soldered there, the two fight for
the pin. See `GPS_SETUP.md` — GPS has to move to UART2 first. Wiring after that change:

| Signal | Pad | Pin |
|---|---|---|
| LED strip data | T1 | PA9 |
| SBUS in (from O4) | R1 | PA10 |
| GPS module RX | T2 | PA2 |
| GPS module TX | R2 | PA3 |
| ELRS | internal | PB10 / PB11 |
| DJI O4 MSP | internal | PC10 / PC11 |

with `resource LED_STRIP 1 A09`.

## ELRS mode (HelloRadio V12 MAX)

```
serial UART1 0 115200 57600 0 115200        # UART1 off
serial UART2 2 115200 115200 0 115200       # GPS
serial UART3 64 115200 57600 0 115200       # ELRS, Serial RX
set serialrx_provider = CRSF
save
```

## SBUS mode (DJI Remote Controller 3)

```
serial UART1 64 115200 57600 0 115200       # SBUS in, Serial RX
serial UART2 2 115200 115200 0 115200       # GPS
serial UART3 0 115200 57600 0 115200        # ELRS off
set serialrx_provider = SBUS
save
```

## Notes

- `save` reboots. Check the **Receiver** tab afterwards and confirm the sticks move the right
  channels before flying.
- The AUX layout is unchanged between modes, but the DJI controller has fewer switches than the
  V12 MAX. Plan which of ARM / ANGLE / TURTLE / PREARM / BEEPER / LEDLOW you can reach, and expect
  to re-map some of them on the DJI side.
- **PREARM on AUX3 will block arming** if the DJI controller has no switch assigned to it. Either
  map one or remove `aux 5 36 2 1700 2100 0 0` while in SBUS mode.
- SBUS is an inverted signal; Betaflight handles this on the G4's UARTs with `sbus_inversion = ON`,
  which is the default. Do not change it.
- Telemetry over SBUS is limited compared with CRSF. The GPS position tracking via the ELRS Lua
  script is a CRSF feature and will not be available on the DJI controller.
