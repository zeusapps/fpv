## Purpose

The last-resort recovery path for a quad that is down and out of sight: an EdgeTX widget on the
HelloRadio V12 MAX that turns the last received GPS position into a QR code a phone camera can
scan straight into Google Maps. It is the backup for GPS Rescue, so it has to work in the
conditions where the rescue already failed — telemetry lost, quad on the ground, possibly after
the radio has been switched off and on.

## ADDED Requirements

### Requirement: A displayed QR code SHALL be scannable independently of the radio theme

The widget MUST set both the QR code's foreground and background colour explicitly. It MUST NOT
rely on the EdgeTX defaults.

Per the EdgeTX Lua reference for `lvgl.qrcode` (luadoc.edgetx.org, EdgeTX 2.11), an unset
`bgColor` defaults to `COLOR_THEME_SECONDARY3` and, as a common LVGL object setting, an unset
`color` defaults to `COLOR_THEME_SECONDARY1`. Both are theme variables, so the contrast between
the modules and the quiet zone is whatever the active theme happens to produce — on a dark theme
this can approach dark-on-dark. The same reference requires `w` and `h` to be equal for a valid
code.

The failing observation is that the code renders and looks plausible on screen while a phone
refuses to lock onto it. "It displays" is not evidence; only a successful scan is.

#### Scenario: Dark theme

- **WHEN** the radio is set to a dark theme and the widget is showing a fix
- **THEN** a phone camera decodes the code and offers the Google Maps link on the first attempt

#### Scenario: Light theme

- **WHEN** the radio is set to a light theme and the widget is showing the same fix
- **THEN** the code decodes to the identical URL, with no change in appearance of the code itself

#### Scenario: Widget colour options changed

- **WHEN** the user sets `BgColor` and `TxtColor` to arbitrary values in the widget settings
- **THEN** the panel and label colours change and the QR code's own black-on-white is unaffected

### Requirement: A displayed position SHALL always carry its age or provenance

The widget MUST NOT render a coordinate or a QR code without an accompanying indicator of how old
the underlying fix is: live, seconds/minutes since the last received fix, or restored from the SD
card with unknown age. This MUST hold in every widget zone geometry the widget accepts, including
square zones.

A stale position is not a harmless inconvenience. Walking to a fix taken thirty seconds before a
crash is a different search from walking to one restored from a previous flight, and the two are
indistinguishable from the coordinates alone.

The falsifying observation: place the widget in a square zone with a saved fix and no drone
powered. If the display shows a QR and coordinates but no `SAVED` marker, this requirement is not
met. A zone geometry the widget cannot satisfy MUST show the age in place of the QR rather than
silently dropping it.

#### Scenario: Square zone with a restored fix

- **WHEN** the widget occupies a zone whose height and width are equal and the fix was restored
  from the SD card
- **THEN** the display includes a `SAVED` indicator alongside the code

#### Scenario: Telemetry lost mid-flight

- **WHEN** the drone's telemetry stops and no new fix arrives for two minutes
- **THEN** the indicator counts up from `LIVE` through seconds to minutes rather than continuing
  to read `LIVE`

### Requirement: The last valid fix SHALL survive a radio power cycle

The widget MUST persist a received fix to the radio's SD card and restore it on the next start.
The write MUST be rate-limited rather than issued per frame.

This is the case the feature exists for: the quad is down, the search takes longer than the
radio's battery or the user's patience, and the radio gets switched off.

#### Scenario: Power cycle with no drone powered

- **WHEN** the radio receives a fix, is switched off, and is switched back on with the drone
  unpowered
- **THEN** the widget shows the same coordinates it last displayed, marked as restored

#### Scenario: SD card path unavailable

- **WHEN** the `/LOGS/` folder does not exist on the card
- **THEN** the widget continues to display live positions normally and does not retry the write
  on every frame

### Requirement: An absent or invalid fix SHALL NOT be presented as a position

The widget MUST distinguish "no fix yet" from a fix at coordinates `0, 0`. A GPS sensor reporting
zeros is the documented signature of a working receiver that has not acquired — `README.md` and
`pavo20-pro-ii/GPS_SETUP.md` record that zeros mean working-without-fix while missing elements
mean nothing is being parsed. Encoding `0.000000,0.000000` into a QR would send the user to the
Gulf of Guinea.

#### Scenario: Drone powered indoors, no satellites

- **WHEN** the drone is powered, telemetry is flowing, and the GPS sensor reports zeros
- **THEN** the widget shows a waiting state and renders no QR code

#### Scenario: GPS sensor absent entirely

- **WHEN** no telemetry sensor named `GPS` exists on the model
- **THEN** the widget shows a waiting state and does not error or blank the screen

### Requirement: The widget SHALL render entirely within its assigned zone

All drawn elements MUST fall inside the zone the user allocated. Computed dimensions MUST remain
positive for every zone size the radio will assign, including the smallest.

EdgeTX's LVGL reference documents `x` and `y` as "relative to the top left corner of the parent
object" without stating what the parent is for a widget script, and the reference's own LVGL
widget example offsets its labels by `wgt.zone.x`. Which of those applies is unresolved and cannot
be settled from documentation — see `design.md`.

The falsifying observation is a half-screen zone, not a full-screen one: at full screen the zone
origin is `0, 0` and both interpretations produce identical output, so a full-screen test proves
nothing about this requirement.

#### Scenario: Half-screen zone

- **WHEN** the widget is assigned to a zone that does not start at the screen origin
- **THEN** the QR code and text appear inside that zone and do not overlap adjacent widgets

#### Scenario: Smallest assignable zone

- **WHEN** the widget is assigned the smallest zone the radio offers
- **THEN** it renders a legible status without producing a zero or negative-sized element

### Requirement: The widget SHALL NOT degrade radio behaviour while running

Work performed per frame MUST be bounded. QR rebuilds MUST be rate-limited, and SD card access
MUST NOT occur on every poll, whether the previous write succeeded or failed.

The widget runs in the background on every screen and is intended to be left visible in flight.
Anything that stalls the radio's main loop competes with the control link.

#### Scenario: Left on screen through a full flight

- **WHEN** the widget is displayed for an entire pack while the position updates continuously
- **THEN** stick response, audio callouts and telemetry alarms behave no differently than with the
  widget removed

#### Scenario: Position changing continuously

- **WHEN** a new distinct fix arrives several times per second
- **THEN** the QR is rebuilt at the configured rate limit, not once per received fix

### Requirement: Radio-side documentation SHALL NOT restate per-aircraft flight controller settings

Documentation under `radio/` MUST cross-reference the owning aircraft folder for any Betaflight
setting that differs between aircraft, rather than stating a value. Where it names a setting at
all, it MUST name the firmware version the value was read at.

The bundled widget README instructed the reader to set the GPS protocol to `UBLOX` with auto-baud.
Applied to the Pavo20 Pro II that is the documented wrong answer: its BZ-181 never answers a UBX
`MON-VER`, so the UBLOX driver cannot leave `DETECT_BAUD` (`gps.c`, read at Betaflight 2025.12.2),
and the aircraft runs the NMEA provider at a fixed 115200 with auto-config off. The advice was
correct for the FireFly25 it was written against and wrong for the aircraft the radio is most
often bound to. Generic radio documentation that names aircraft settings will drift into
contradicting the aircraft folders.

#### Scenario: A reader follows the radio setup guide for the Pavo20

- **WHEN** a reader works through `radio/README.md` looking for GPS configuration
- **THEN** they are sent to `pavo20-pro-ii/GPS_SETUP.md` and find no protocol or baud value stated
  under `radio/`

#### Scenario: A reader follows the radio setup guide for return-to-home

- **WHEN** a reader looks for GPS Rescue setup under `radio/`
- **THEN** they are sent to `pavo20-pro-ii/FAILSAFE.md`, including its untested status, rather than
  finding a second set of rescue values
