local wezterm = require 'wezterm'
local act = wezterm.action

local color_scheme = "GruvboxDarkHard"

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local tab_number = tab.tab_index + 1

  if tab.tab_title and #tab.tab_title > 0 then
    return '  ' .. tab_number .. ': ' .. tab.tab_title .. '  '
  else
    return '  ' .. tab_number .. '  '
  end
end)

return {
  front_end = "WebGpu",

  initial_cols = 160,  -- width in columns
  initial_rows = 40,   -- height in rows

  font = wezterm.font_with_fallback({
    "Iosevka Term",
    "Symbols Nerd Font",
  }),
  font_size = 16.0,

  color_scheme = color_scheme,
  window_background_opacity = 0.96,
  macos_window_background_blur = 0,

  scrollback_lines = 10000,

  hide_tab_bar_if_only_one_tab = false,
  use_fancy_tab_bar = false,
  tab_bar_at_bottom = true,

  window_padding = {
    left = 8,
    right = 8,
    top = 8,
    bottom = 8,
  },

  leader = { key = 's', mods = 'CTRL', timeout_milliseconds = 1000 },

  keys = {
    -- Splitting (leader + - or |)
    { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
    { key = '\\', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
    { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },

    -- Pane navigation (leader + hjkl)
    { key = 'LeftArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
    { key = 'DownArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
    { key = 'UpArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
    { key = 'RightArrow', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },

    -- Close pane (leader + x)
    { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },

    -- Zoom pane (leader + z)
    { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },

    -- Tab management
    { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
    { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
    { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
    { key = '1', mods = 'LEADER', action = act.ActivateTab(0) },
    { key = '2', mods = 'LEADER', action = act.ActivateTab(1) },
    { key = '3', mods = 'LEADER', action = act.ActivateTab(2) },
    { key = '4', mods = 'LEADER', action = act.ActivateTab(3) },
    { key = '5', mods = 'LEADER', action = act.ActivateTab(4) },

    -- Rename tab (leader + ,)
    { key = ',', mods = 'LEADER', action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    }},

    -- Quick launcher (CMD+k for fuzzy finder)
    { key = 'k', mods = 'CMD', action = act.ShowLauncherArgs { flags = 'FUZZY|TABS|WORKSPACES' } },

    -- Copy/Paste (native macOS)
    { key = 'c', mods = 'CMD', action = act.CopyTo 'Clipboard' },
    { key = 'v', mods = 'CMD', action = act.PasteFrom 'Clipboard' },
  },

  enable_scroll_bar = false,
  enable_wayland = false, -- not needed on macOS

  hyperlink_rules = wezterm.default_hyperlink_rules(),
  inactive_pane_hsb = {
    saturation = 0.8,
    brightness = 0.6,
  },
  cursor_blink_rate = 500,
  default_cursor_style = 'BlinkingBar',

  selection_word_boundary = " \t\n{}[]()\"'`<>│┃.,",

  colors = {
    tab_bar = {
      -- Background of the tab bar
      background = '#504945',  -- Gruvbox dark background

      -- Active tab colors
      active_tab = {
        bg_color = '#fabd2f',  -- Gruvbox yellow
        fg_color = '#1d2021',  -- Dark text
        intensity = 'Bold',
      },

      -- Inactive tab colors
      inactive_tab = {
        bg_color = '#3c3836',  -- Gruvbox dark gray
        fg_color = '#a89984',  -- Gruvbox light gray
      },

      -- Inactive tab on hover
      inactive_tab_hover = {
        bg_color = '#504945',  -- Slightly lighter gray
        fg_color = '#d5c4a1',  -- Lighter text
      },

      -- New tab button
      new_tab = {
        bg_color = '#3c3836',
        fg_color = '#a89984',
      },

      new_tab_hover = {
        bg_color = '#fabd2f',
        fg_color = '#1d2021',
      },
    },
  },
}
