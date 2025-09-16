-- ui_api.lua
-- Minimal UI kit that wraps your existing helpers and exposes a stable API.

local M = {}

-- ==== STATE ====
local screenX, screenY = render.get_viewport_size()
local currentX, currentY = 120, 120
local shouldRender = true
local dragging, dragX, dragY = false, 0, 0

-- ==== CONFIG ====
local function rgba(r,g,b,a) return {r=r,g=g,b=b,a=a} end
local color = {
  background = rgba(25,25,25,255),
  text       = rgba(255,255,255,255),
  disabled   = rgba(145,145,145,190),
  enabled    = rgba(128,0,128,255),
  accent     = rgba(8,8,8,120)
}
local WINDOW_W, WINDOW_H = 250, 400
local HEADER_H = 25
local CONTENT_LEFT = 15
local CHAR_W, CHAR_H, V_ADJ = 8, 18, -1
local _ly = 35

-- font
local font = render.create_font(("smallest_pixel-7"), 16, 400)

-- ==== LOW-LEVEL HELPERS (kept compatible with your file) ====
local function isMouseInArea(x, y, w, h)
  local mx, my = input.get_mouse_position()
  return (mx >= x and mx <= x + w) and (my >= y and my <= y + h)
end

local function drawBox(offsetX, offsetY, width, height, col, outline, filled)
  local x = currentX + offsetX
  local y = currentY + offsetY
  render.draw_rectangle(x, y, width, height, col.r, col.g, col.b, col.a, 1, filled)
  if outline then
    render.draw_rectangle(x-1, y-1, width+2, height+2, color.accent.r, color.accent.g, color.accent.b, color.accent.a, 1, false)
  end
end

local function drawText(f, text, offsetX, offsetY, col, outline_thickness)
  render.draw_text(f, text, currentX+offsetX, currentY+offsetY, col.r, col.g, col.b, col.a,
                   outline_thickness, color.accent.r, color.accent.g, color.accent.b, color.accent.a)
end

-- ==== PUBLIC: CONFIG / THEME ====
function M.set_position(x, y) currentX, currentY = x, y end
function M.get_position() return currentX, currentY end
function M.set_colors(tbl) for k,v in pairs(tbl) do color[k] = v end end
function M.set_font(name, size, weight) font = render.create_font((name), size or 16, weight or 400) end
function M.set_window_size(w, h) WINDOW_W, WINDOW_H = w, h end

-- ==== PUBLIC: LAYOUT ====
local function ui_reset() _ly = HEADER_H + 10 end
local ROW_H_ITEM, SPACER_TOP_PAD, SPACER_BOTTOM_PAD = 20, 8, 16

function M.spacer(label)
  _ly = _ly + SPACER_TOP_PAD
  local pad = 20
  local yCenter = currentY + _ly
  local x1 = currentX + pad
  local x2 = currentX + WINDOW_W - pad
  local tw = #label * CHAR_W
  local textRelX = (WINDOW_W - tw) / 2
  local textRelY = _ly - (CHAR_H / 2) + V_ADJ
  local textAbsX = currentX + textRelX
  local gap = 8

  render.draw_line(x1, yCenter, textAbsX - gap, yCenter, color.text.r, color.text.g, color.text.b, color.text.a, 1)
  render.draw_line(textAbsX + tw + gap, yCenter, x2, yCenter, color.text.r, color.text.g, color.text.b, color.text.a, 1)
  drawText(font, label, textRelX, textRelY, color.text, 1)
  _ly = _ly + SPACER_BOTTOM_PAD
end

function M.checkbox(label, value)
  -- label
  drawText(font, label, CONTENT_LEFT, _ly-5, color.text, 1)

  -- control
  local boxX, boxY, w, h = 210, _ly, 25, 10
  local absX, absY = currentX + boxX, currentY + boxY
  local hover = isMouseInArea(absX, absY, w, h)

  drawBox(boxX, boxY, w, h, color.text, true, value and true or false)

  if hover then
    drawBox(boxX, boxY, w, h, rgba(255,255,255,75), false, true)
    if input.is_key_pressed(0x01) then value = not value end
  end

  _ly = _ly + ROW_H_ITEM
  return value
end

function M.slider_int(label, value, min, max, step)
  min  = min or 0
  max  = max or 10
  step = step or 1

  -- label on a slightly raised baseline
  drawText(font, label, CONTENT_LEFT, _ly-5, color.text, 1)

  -- controls use the same adjusted baseline so they align visually
  local lx, rx = 205, 235
  local baseline = _ly - 3     -- <-- tweak this to nudge up/down 1–2 px

  local pad = 2
  local lAbsX, lAbsY = currentX + lx, currentY + baseline
  local rAbsX, rAbsY = currentX + rx, currentY + baseline
  local hitW, hitH   = CHAR_W + pad*2, CHAR_H + pad*2

  if isMouseInArea(lAbsX - pad, lAbsY - pad, hitW, hitH) then
    drawBox(lx - pad, baseline - pad, hitW, hitH, rgba(255,255,255,40), true, false)
    if input.is_key_pressed(0x01) then value = math.max(min, value - step) end
  end
  if isMouseInArea(rAbsX - pad, rAbsY - pad, hitW, hitH) then
    drawBox(rx - pad, baseline - pad, hitW, hitH, rgba(255,255,255,40), true, false)
    if input.is_key_pressed(0x01) then value = math.min(max, value + step) end
  end

  local s  = tostring(value)
  local tw = #s * CHAR_W
  local cx = 222 - math.floor(tw/2)

  -- draw on the same baseline
  drawText(font, "<", lx, baseline, color.text, 1)
  drawText(font, s,  cx, baseline, color.text, 1)
  drawText(font, ">", rx, baseline, color.text, 1)

  _ly = _ly + ROW_H_ITEM
  return value
end

-- ==== PUBLIC: WINDOW + INPUT ====
local function header_interactions()
  local isClicking = input.is_key_down(0x01)
  local mx, my = input.get_mouse_position()

  if not dragging and isClicking and isMouseInArea(currentX, currentY, WINDOW_W, HEADER_H) then
    dragging = true
    dragX, dragY = mx - currentX, my - currentY
  end

  if dragging then
    if isClicking then
      currentX = math.max(0, math.min(mx - dragX, screenX - WINDOW_W))
      currentY = math.max(0, math.min(my - dragY, screenY - WINDOW_H))
    else
      dragging = false
    end
  end
end

function M.begin(title)
  header_interactions()

  -- shadow can be user-controlled; provide a thin default here
  M.shadow_stack({r=3,g=3,b=3}, 80, 4, 2)

  -- window + header
  drawBox(0, 0, WINDOW_W, WINDOW_H, color.background, true, true)
  drawBox(0, 0, WINDOW_W, HEADER_H, color.accent, true, true)
  drawText(font, title or "window", 12, 3, color.text, 0)

  -- simple close button
  drawText(font, "X", WINDOW_W-15, 3, color.text, 0)
  if isMouseInArea(currentX + WINDOW_W - 25, currentY, 25, HEADER_H) then
    drawBox(WINDOW_W-25, 0, 25, HEADER_H, rgba(255,0,0,120), false, true)
    drawText(font, "X", WINDOW_W-15, 3, color.text, 0)
    if input.is_key_down(0x01) then shouldRender = false end
  end

  ui_reset()
end

function M.finish()
  -- no-op placeholder if you ever need post-body drawing
end

function M.toggle_key(vk)  -- default VK_INSERT = 0x2D
  if input.is_key_pressed(vk or 0x2D) then shouldRender = not shouldRender end
  return shouldRender
end

-- ==== PUBLIC: SHADOW STACK ====
-- rgb: {r,g,b}; start_alpha defaults 255; layers = number of layers; offset_step = pixels per layer
function M.shadow_stack(rgb, start_alpha, layers, offset_step)
  rgb = rgb or {r=3,g=3,b=3}
  local a0 = start_alpha or 255
  local n  = layers or 20
  local step = offset_step or 3

  for i = 0, n-1 do
    local alpha = math.max(0, a0 - i)
    local o = step * (i+1)
    -- negative X, positive Y like your original
    drawBox(-o, o, WINDOW_W, WINDOW_H, rgba(rgb.r, rgb.g, rgb.b, alpha), false, true)
  end
end

-- ==== PUBLIC: MAIN RENDER HOOK ====
-- Pass a callback that draws your controls each frame when visible.
-- Example:
--   ui.on_render(function(ui)
--     ui.spacer("Aimbot")
--     enabled = ui.checkbox("Enabled", enabled)
--     speed   = ui.slider_int("Speed", speed, 0, 10, 1)
--   end)
function M.on_render(body_fn, title)
  if not M.toggle_key(0x2D) then return end
  if not body_fn then return end
  M.begin(title or "menu")
  body_fn(M)
  M.finish()
end

-- expose a couple of useful things
M.rgba   = rgba
M.color  = color

return M
