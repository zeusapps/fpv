---------------------------------------------------------------------
-- GPS QR  -  "find my drone" widget for EdgeTX color radios
--
-- Shows the last known GPS position as a QR code. Scan it with your
-- phone camera and it opens Google Maps with a pin on the drone.
--
--  * Keeps the last valid fix after telemetry is lost (failsafe/crash)
--  * Saves the fix to the SD card, so it survives a radio power cycle
--  * Uses the native LVGL QR control -> no CPU-heavy Lua QR generation
--
-- Status words: LIVE      = fix received in the last 5 s
--               47s ago   = time since the last received fix
--               SAVED     = fix restored from SD (radio was power-cycled)
--
-- Widget settings (long-press the widget -> settings):
--   BgColor  - panel background color        (default: near-black)
--   TxtColor - text color                    (default: white)
--   SolidBG  - draw the panel at all; turn off for a transparent
--              widget that uses your theme background (default: on)
-- Those three affect the panel and the text only. The QR code is pinned
-- to black-on-white below and is not themeable - an unset colour falls
-- back to a theme variable, which on a dark theme can render the code
-- dark-on-dark and unscannable. See radio/CODE_REVIEW.md.
--
-- Requires: EdgeTX 2.11+ (LVGL Lua API), color screen radio
-- Install:  copy this folder so the file is at /WIDGETS/GPSQR/main.lua
-- Source:   version-controlled at radio/WIDGETS/GPSQR/main.lua in the FPV
--           repo. Edit it there and copy to the card, not the other way.
---------------------------------------------------------------------

local SENSOR        = "GPS"                          -- telemetry sensor name
local URL_FMT       = "https://maps.google.com/?q=%.6f,%.6f"
local SAVE_PATH     = "/LOGS/gpsqr_last.txt"
local REBUILD_TICKS = 500    -- rebuild QR at most every 5 s (1 tick = 10 ms)
local SAVE_TICKS    = 1000   -- write fix to SD at most every 10 s
local LIVE_AGE_S    = 5      -- fix younger than this counts as "LIVE"
local MIN_QR        = 56     -- below this a phone will not lock onto the code;
                             -- smaller zones fall back to text-only
local TEXT_H        = 18     -- height reserved for one SMLSIZE status line

local DEF_BG = (lcd and lcd.RGB) and lcd.RGB(24, 26, 30) or BLACK

-- user-configurable widget options (edit in the widget settings UI)
local options = {
  { "BgColor",  COLOR, DEF_BG },
  { "TxtColor", COLOR, WHITE  },
  { "SolidBG",  BOOL,  1      },
}

local function hasFix(v)
  return type(v) == "table" and v.lat ~= nil and v.lon ~= nil
         and (v.lat ~= 0 or v.lon ~= 0)
end

-- restore the last saved fix from the SD card (after a power cycle)
local function loadSaved(w)
  local f = io.open(SAVE_PATH, "r")
  if not f then return end
  local s = io.read(f, 128)
  io.close(f)
  if not s then return end
  local lat, lon = string.match(s, "(-?[%d%.]+),(-?[%d%.]+)")
  lat, lon = tonumber(lat), tonumber(lon)
  if lat and lon and (lat ~= 0 or lon ~= 0) then
    w.lat, w.lon = lat, lon
    w.fromFile = true          -- fix restored from disk, age unknown
  end
end

local function saveFix(w)
  local f = io.open(SAVE_PATH, "w")
  if f then
    io.write(f, string.format("%.6f,%.6f", w.lat, w.lon))
    io.close(f)
    w.needsSave = false
  end
  -- Stamp the attempt, not the success. If the open fails - no /LOGS
  -- folder, no card, card full - leaving lastSave nil makes the rate-limit
  -- test in poll() true forever, and poll() runs once per frame, so the
  -- widget would hammer io.open on every refresh. A failed write now backs
  -- off for SAVE_TICKS exactly like a successful one.
  -- needsSave is deliberately NOT cleared on failure: a quad that has
  -- crashed stops moving, so its coordinates stop changing, and clearing
  -- the flag would mean that fix is never written at all.
  w.lastSave = getTime()
end

-- poll telemetry; runs both when visible (refresh) and hidden (background)
local function poll(w)
  local v = getValue(SENSOR)
  if hasFix(v) then
    if v.lat ~= w.lat or v.lon ~= w.lon then
      w.lat, w.lon = v.lat, v.lon
      w.needsSave = true
    end
    w.lastFixTime = getTime()
    w.fromFile = false
  end
  if w.needsSave and w.lat and
     (w.lastSave == nil or getTime() - w.lastSave > SAVE_TICKS) then
    saveFix(w)
  end
end

-- short status word that fits next to / below the QR code
local function statusShort(w)
  if w.fromFile then return "SAVED" end
  if w.lastFixTime == nil then return "..." end
  local age = (getTime() - w.lastFixTime) / 100
  if age < LIVE_AGE_S then
    return "LIVE"
  elseif age < 120 then
    return string.format("%ds ago", math.floor(age))
  else
    return string.format("%dm ago", math.floor(age / 60))
  end
end

-- one-line status + coordinates, for the portrait layout
local function statusLine(w)
  return statusShort(w) ..
         string.format("  %.5f %.5f", w.lat, w.lon)
end

local function buildUI(w)
  lvgl.clear()
  w.builtW, w.builtH = w.zone.w, w.zone.h

  local W, H = w.zone.w, w.zone.h
  local pad  = 6
  local bg   = w.options.BgColor  or DEF_BG
  local tc   = w.options.TxtColor or WHITE
  local ui   = {}

  if w.options.SolidBG == nil or w.options.SolidBG ~= 0 then
    -- our own panel: predictable text contrast on any theme
    ui[#ui + 1] = { type = "rectangle", x = 0, y = 0, w = W, h = H,
                    filled = true, rounded = 4, color = bg }
  end

  if w.lat == nil then
    ui[#ui + 1] = { type = "label", x = pad, y = pad, color = tc,
                    text = "Waiting for GPS fix..." }
    lvgl.build(ui)
    w.builtData = nil
    return
  end

  local data = string.format(URL_FMT, w.lat, w.lon)

  local wide = (W >= H + 70)
  -- WIDE: QR on the left, capped so the text column keeps >= ~94 px.
  -- PORTRAIT / SQUARE: QR centered, with room for the status line always
  -- reserved below it. The status is not optional - without it a fix
  -- restored from the card is indistinguishable from a live one.
  local size = wide and math.min(H - 2 * pad, W - 100)
                     or math.min(W - 2 * pad, H - 2 * pad - TEXT_H - 4)

  if size < MIN_QR then
    -- Zone too small for a code a phone can lock onto. Show the numbers -
    -- they can still be typed into a map by hand - rather than handing
    -- lvgl.qrcode a zero or negative dimension.
    ui[#ui + 1] = { type = "label", x = pad, y = pad, color = tc,
                    font = SMLSIZE,
                    text = function() return statusShort(w) end }
    ui[#ui + 1] = { type = "label", x = pad, y = pad + TEXT_H, color = tc,
                    font = SMLSIZE, text = string.format("%.5f", w.lat) }
    ui[#ui + 1] = { type = "label", x = pad, y = pad + 2 * TEXT_H, color = tc,
                    font = SMLSIZE, text = string.format("%.5f", w.lon) }
    lvgl.build(ui)
    w.builtData = data
    return
  end

  if wide then
    local tx = 2 * pad + size
    ui[#ui + 1] = { type = "qrcode", x = pad,
                    y = math.floor((H - size) / 2),
                    w = size, h = size, data = data,
                    color = BLACK, bgColor = WHITE }
    ui[#ui + 1] = { type = "label", x = tx, y = pad + 2,
                    color = tc, font = MIDSIZE,
                    text = function() return statusShort(w) end }
    ui[#ui + 1] = { type = "label", x = tx, y = pad + 36, color = tc,
                    text = string.format("%.5f", w.lat) }
    ui[#ui + 1] = { type = "label", x = tx, y = pad + 54, color = tc,
                    text = string.format("%.5f", w.lon) }
    if H >= 110 then
      ui[#ui + 1] = { type = "label", x = tx, y = H - pad - 16,
                      color = tc, font = SMLSIZE, text = "Scan > Maps" }
    end
  else
    local qx = math.floor((W - size) / 2)
    local qy = math.floor((H - size - TEXT_H - 4) / 2)
    ui[#ui + 1] = { type = "qrcode", x = qx, y = qy,
                    w = size, h = size, data = data,
                    color = BLACK, bgColor = WHITE }
    ui[#ui + 1] = { type = "label", x = pad, y = qy + size + 4,
                    color = tc, font = SMLSIZE,
                    text = function() return statusLine(w) end }
  end

  lvgl.build(ui)
  w.builtData = data
end

local function create(zone, options)
  local w = { zone = zone, options = options }
  loadSaved(w)
  return w
end

local function update(w, options)
  w.options = options
  buildUI(w)     -- also applies color changes from the settings UI
end

local function background(w)
  poll(w)   -- keep capturing the position even when widget is hidden
end

local function refresh(w, event, touchState)
  poll(w)
  local data = w.lat and string.format(URL_FMT, w.lat, w.lon) or nil
  local sizeChanged = (w.builtW ~= w.zone.w) or (w.builtH ~= w.zone.h)
  local dataChanged = (data ~= w.builtData)
  if sizeChanged
     or (dataChanged and w.builtData == nil)  -- first fix: show instantly
     or (dataChanged and (w.lastBuild == nil
         or getTime() - w.lastBuild > REBUILD_TICKS)) then
    buildUI(w)
    w.lastBuild = getTime()
  end
end

return {
  name = "GPSQR",
  options = options,
  create = create,
  update = update,
  refresh = refresh,
  background = background,
  useLvgl = true,
}
