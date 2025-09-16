local ui = require("aMenu")

-- State you own:
local aimbot_enabled = false
local dont_miss      = true
local test_slider    = 3

-- Theme/pos overrides (optional)
ui.set_position(200, 200)
ui.set_window_size(250, 400)
ui.set_colors({ accent = ui.rgba(8,8,8,150) })
ui.set_font("smallest_pixel-7", 16, 400)

-- Hook into your engine tick
local function draw_menu(_ui)
  _ui.spacer("Aimbot")
  aimbot_enabled = _ui.checkbox("Enabled",    aimbot_enabled)
  dont_miss      = _ui.checkbox("Dont Miss",  dont_miss)

  _ui.spacer("Visuals")
  test_slider    = _ui.slider_int("TEST", test_slider, 0, 9, 1)

  _ui.spacer("Misc")
  -- add more controls...
end

function on_render()
  ui.on_render(draw_menu, "menuuuuu")
end

engine.register_on_engine_tick(on_render)
