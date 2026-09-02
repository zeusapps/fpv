# DJI O4 Air Unit Pro on the Pavo20 Pro II

## Wiring

The Pavo20 Pro II AIO has a dedicated **6-pin HD VTX connector**. The O4 plugs straight into it —
no soldering. The board carries a dual BEC: **9V 2A** for the O4 and **5V 3A** for everything else.

The O4 air unit talks to Betaflight over **UART4**.

> The kit includes two canopies — one for the **O4 Pro** air unit and one for the **O4 Wide**.
> Use the one matching your air unit; the camera cutouts differ.

## Betaflight port config

In **Ports** tab, on UART4: enable **MSP** and set **VTX (MSP)**.

Equivalent CLI (`serial 3` = UART4, `131073` = VTX_MSP + MSP):

```
serial 3 131073 115200 57600 0 115200
```

## OSD over MSP DisplayPort

```
set osd_displayport_device = MSP
```

The O4 renders the OSD canvas itself. Two consequences:

1. **The `feature OSD` chip on the board is not what you are seeing.** OSD element positions from an
   analog build will land in the wrong place — the digital canvas is a different size (typically
   53x20 or 60x22 depending on goggle/air unit mode, versus 30x16 for analog PAL).
2. Place elements using the Betaflight Configurator **OSD tab** with the correct video format
   selected, not by hand-editing `osd_*_pos` integers.

Also make sure **Canvas Mode / MSP OSD** is enabled in the DJI goggles' settings, otherwise you get
the DJI native OSD and none of your Betaflight elements.

## VTX control from Betaflight

With `VTX (MSP)` enabled you can change channel and power from the Betaflight **Video Transmitter**
tab or from the OSD menu, and `osd_sys_vtx_temp_pos` will report air unit temperature. The O4 will
thermally throttle in a ducted frame with no airflow, so **put the VTX temperature element in your
OSD** — it is the early warning before the video drops out on a hovering cinewhoop.

## Recommended OSD elements for this build

Beyond the usual voltage/timer/craft name:

- `osd_sys_vtx_temp` — O4 thermal throttling warning (see above)
- `osd_avg_cell_voltage` — more useful than pack voltage for judging when to land
- `osd_link_quality` and `osd_rssi_dbm` — ELRS link health
- `osd_esc_tmp` — ducted motors run hot
- `osd_warnings` — leave this on

## Pre-flight checks specific to the O4

- **Record on the air unit, not just the goggles.** The O4 Pro records locally at higher quality;
  that is the whole reason to fly a cinewhoop.
- Set the goggles to the same **channel/band** if you fly with others.
- The O4 draws meaningful current. On a 550mAh 3S pack the video system is a real fraction of your
  flight time — the ~6.5 min figure already accounts for it.
- Let the air unit boot fully before arming; the OSD appearing is your signal.

## Known issue

Do **not** flash Betaflight **2025.12.1** on the F4 2-3S 20A V1 board. It caused intermittent
no-boot: no startup beeps and no Betaflight OSD, while ELRS and DJI video still worked — which makes
it look like an OSD problem when the FC has actually not booted. See
[betaflight#14890](https://github.com/betaflight/betaflight/issues/14890). Use 2025.12.2.
