# Binding an ELRS radio to the Meteor75 Pro

Written for the Radiomaster Pocket, which flew this quad first. The Meteor is now flown with the
**HelloRadio V12 MAX**; it also runs EdgeTX with an internal ELRS module, so the same steps apply —
open the ExpressLRS Lua script from the radio's Tools / SYS menu. The Pavo20's
`pavo20-pro-ii/BINDING_GUIDE.md` covers the V12 MAX specifically, including the ELRS switch mode.

The receiver is on **UART3** with `serialrx_provider = CRSF` (confirmed on the aircraft 2026-09-29,
and the `BETAFPVG473` target default). An earlier version of this guide named the wrong UART.

## Prerequisites

- Both the Radiomaster Pocket's internal ELRS module and the Meteor75 Pro's ELRS receiver must be on **compatible firmware versions** (the major version number must match, e.g. both on 3.x)
- Have a USB cable ready to connect the drone to Betaflight Configurator for verification

## Method 1: Binding Phrase (Recommended)

A binding phrase makes your TX and RX automatically connect every time — no manual binding needed. Both devices must be flashed with the **same phrase**.

### Setting the phrase on the Radiomaster Pocket:

1. Power on the radio
2. Press the **SYS** button to open the Tools menu
3. Scroll to **ExpressLRS** Lua script and press Enter
4. In the Lua script, select **WiFi Connectivity** → enable WiFi on the TX module
5. Connect to the module's WiFi hotspot from your phone/computer
6. In the web UI, set your **Binding Phrase** (use something unique like your pilot name)
7. Save and the module will reboot

### Setting the phrase on the Meteor75 Pro receiver:

1. Power the drone via battery (no need to arm)
2. The ELRS receiver should start its own WiFi hotspot after ~60 seconds of no connection (LED will change pattern)
3. Connect to the receiver's WiFi from your phone/computer
4. In the web UI, set the **same Binding Phrase** as your transmitter
5. Save — the receiver will reboot and should auto-connect to your radio

## Method 2: Traditional Bind Mode

Use this if you don't want to set a binding phrase.

### Put the receiver into bind mode (pick one):

**Option A — Betaflight CLI (easiest, requires BF 4.5+):**
1. Connect the drone to Betaflight Configurator via USB
2. Go to the **CLI** tab
3. Type `bind_rx` and press Enter
4. The receiver LED should start quick double-blinking (bind mode)

**Option B — Boot button:**
1. With the drone powered, hold the ELRS receiver's **boot button** for ~1.5 seconds
2. The receiver LED should start quick double-blinking (bind mode)

**Option C — Power cycle (if no button access):**
1. Power cycle the drone 3 times quickly (power on for ~2 seconds, power off, repeat)
2. After the third power-on, the receiver LED should quick double-blink (bind mode)

### Initiate binding from the Radiomaster Pocket:

1. Power on the radio
2. Press the **SYS** button → open the **ExpressLRS** Lua script
3. Select **Bind** in the Lua script
4. Wait until the receiver LED goes **solid** — binding is complete
5. Power cycle the drone to confirm it reconnects automatically

## Verifying the Connection

1. Open the **ExpressLRS Lua script** on the Radiomaster Pocket — a **"C"** in the top-right corner confirms the link is active
2. Connect the drone to **Betaflight Configurator** via USB
3. Go to the **Receiver** tab
4. Move the sticks and switches — you should see the channel bars responding
5. Verify the channel order matches AETR (Aileron, Elevator, Throttle, Rudder) — this is the ELRS default and should match the radio's defaults
6. Check CH5–CH9 against the switch table in `README.md` — in particular that CH9 reaches all three positions, since it selects the rate profile

## Troubleshooting

- **No response in Receiver tab:** Check that Serial RX is enabled on **UART3** in the Ports tab, and `serialrx_provider` is set to `CRSF` (`serial 2 64` in the CLI). If the SBUS config was pasted last, re-paste `M75_PRO_ELRS_V1.txt`
- **Sticks move wrong channels:** Channel map mismatch — verify both radio and Betaflight expect AETR
- **Receiver WiFi doesn't appear:** The RX only enters WiFi mode after ~60 seconds with no TX connection. Make sure the radio is off or not bound
- **Version mismatch:** If binding fails completely, check firmware versions on both devices — major versions must match (e.g. both 3.x or both 4.x)
