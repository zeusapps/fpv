# Pavo20 Pro II — Hardware Reference

**This quad is the 4S / Cube variant.** Confirmed from `board_name BETAFPVG473_V3` in the dump.
The 3S variant is documented below for reference only — do not apply its settings here.

## This quad

| Item | Value |
|---|---|
| Craft name | `Pavo20 Pro II` |
| FC/ESC | BetaFPV Cube G4 2-4S 30A 3-in-1 AIO |
| Betaflight target | `BETAFPVG473_V3` |
| Manufacturer ID | `BEFH` |
| MCU | STM32G474 |
| MCU ID | redacted — per-board serial, read it with `version` in the CLI |
| Firmware | Betaflight 2025.12.2 (Mar 12 2026), MSP API 1.47 |
| Gyro | ICM42688P (target also supports BMI270 / ICM42622P / LSM6DSK320X) |
| Baro | BMP280 / DPS310 on I2C1 |
| Compass | none (`mag_hardware = NONE`) |
| Blackbox | onboard SPI flash (M25P16 on SPI3) |
| Motors | LAVA 1104 5500KV, 12 poles |
| Props | Gemfan D2.2 3-blade, screw-mount |
| Motor protocol | DSHOT300, bidirectional DShot ON |
| Battery | 2S-4S, XT30 |
| Receiver | ExpressLRS / CRSF on UART3 |
| Video | DJI O4 Air Unit Pro on UART4 (MSP DisplayPort) |
| GPS | BZGNSS BZ-181 on UART1 — see `GPS_SETUP.md` |
| LED strip | 14 LEDs, remapped to PA3 (UART2 RX pad) |
| Board orientation | `align_board_roll = 180`, `align_board_yaw = 45` |
| Current sensor | `ibata_scale = 280`, `ibata_offset = 70` |

### Pin map (from the `BETAFPVG473_V3` Betaflight target)

| Signal | Pin | Used for on this quad |
|---|---|---|
| UART1 TX / RX | PA9 / PA10 | **GPS** (BZ-181 TX → PA10) |
| UART2 TX / RX | PA2 / PA3 | disabled; **PA3 repurposed as LED_STRIP** |
| UART3 TX / RX | PB10 / PB11 | **ELRS receiver** (target default for non-SBUS builds) |
| UART4 TX / RX | PC10 / PC11 | **DJI O4** (`MSP_DISPLAYPORT_UART`) |
| LED_STRIP | PB2 (target default) | remapped to PA3 |
| Motors 1-4 | PB0, PB1, PB6, PB9 | |
| Beeper | PA8 (inverted) | |
| VBAT / Current ADC | PA4 / PA0 | |
| PINIO1 | PA13 | box 40, named `VTX PWR` |
| Gyro | SPI1, CS PC14, EXTI PC15, `CW180_DEG` | |
| MAX7456 (analog OSD) | SPI2, CS PB12 | unused — video is digital |

Note the target sets `DEFAULT_ALIGN_BOARD_YAW -45`; this quad overrides it to `+45` with
`align_board_roll = 180`.

### Serial RX depends on the build

The target picks the receiver UART at compile time:

- **ELRS build** → `SERIALRX_UART = USART3`, `SERIALRX_PROVIDER = CRSF`
- **SBUS build** → `SERIALRX_UART = USART1`

This matters: on the SBUS firmware, UART1 is taken by the receiver and is **not** available for GPS.

---

## Variant reference

### 4S (this one)

| Item | Value |
|---|---|
| FC/ESC | BetaFPV Cube G4 2-4S 30A 3-in-1 AIO |
| Target | `BETAFPVG473_V3` |
| MCU | STM32G474 |
| ESC firmware | Bluejay v0.19 (C-X-70) |
| Motors | LAVA 1104 **5500KV** |
| Recommended pack | LAVA II 4S 580mAh (~8.5 min) / 680mAh (~10.5 min) |
| Stock `ibata_scale` | 265 (BetaFPV) — this quad uses 280 |

### 3S

| Item | Value |
|---|---|
| FC/ESC | BetaFPV F4 2-3S 20A AIO (V1.0) |
| Target | `BETAFPVF405` |
| MCU | STM32F405 (units from Aug 2026 may ship AT32F435) |
| Motors | LAVA 1104 **7200KV** |
| Recommended pack | LAVA II 3S 680mAh (~9 min) / LAVA 3S 550mAh 75C (~6.5 min) |

---

## Firmware notes

- This quad runs **2025.12.2**, which is fine.
- **A newer official build exists: BF2025.12.5, released 2026-08-12.** Its changelog is directly
  relevant to this airframe:

  > Fixed serial-port conflicts among GPS, RGB and SBUS:
  > - GPS uses independent UART2
  > - RGB control wire connects to TX1
  > - SBUS is assigned to RX1
  >
  > Note: The LED solder pad needs to be re-routed from TX2 to TX1.

  It also adds new PID profiles for the DJI O4 and optimises gyro calibration. Separate ELRS and
  SBUS images are published, plus matching stock CLI dumps. BetaFPV note the configuration
  firmware does not need flashing separately.

  **Read the layout change before flashing.** BetaFPV's fix moves the LED strip onto **TX1 (PA9)**,
  which is the pin this quad currently uses for **GPS TX**. Their layout assumes GPS on UART2. This
  quad runs GPS on UART1 with the LED on PA3, so adopting 2025.12.5's stock config would require
  rewiring both. See `GPS_SETUP.md`.

  The conflict BetaFPV fixed primarily affects the **SBUS** build, where the target assigns
  `SERIALRX_UART = USART1` — putting GPS on UART1 directly on top of the receiver. On the **ELRS**
  build the receiver is on UART3, so UART1 is genuinely free and this quad's layout is sound.
- Do **not** flash **2025.12.1**. It caused intermittent no-boot on the F4 2-3S 20A V1 board —
  no startup beeps and no Betaflight OSD, while ELRS and DJI video kept working, which makes it
  look like an OSD fault. Betaflight issue
  [#14890](https://github.com/betaflight/betaflight/issues/14890), closed as *not planned*.

### Before any firmware flash

A full chip erase wipes the resource remaps this quad depends on. Save these first — they are in
the dump, but losing them means the LED strip silently stops working:

```
resource LED_STRIP 1 A03
resource SERIAL_TX 2 NONE
resource SERIAL_RX 2 NONE
timer A03 AF2
dma pin A03 0
```
