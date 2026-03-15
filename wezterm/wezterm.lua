local wezterm = require 'wezterm'
local act = wezterm.action

local color_scheme = "GruvboxDarkHard"

local tmux_color_bg = wezterm.color.parse("#5c4a4a")

wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local tab_number = tab.tab_index + 1
  local is_tmux = (tab.active_pane and tab.active_pane.domain_name == "tmux")

  local title = (tab.tab_title and #tab.tab_title > 0) and (': ' .. tab.tab_title) or ''
  local text = '  ' .. tab_number .. title .. '  '

  if is_tmux and not tab.is_active  then
    return {
      { Background = { Color = tmux_color_bg } },
      { Text = text },
    }
  end

  return text
end)

local function basename(path)
  return string.match(path, "([^/]+)$")
end

local function extract_project_from_path(path)
  local home = os.getenv("HOME")
  if not home then
    return nil
  end

  -- Normalize
  path = path:gsub("^file://", "")
  path = path:gsub(home, "~")

  -- ~/work/<project>
  local direct = path:match("^~/work/([^/]+)")
  if direct and direct ~= "toptal" then
    return direct
  end

  -- ~/work/toptal/<project>
  local toptal = path:match("^~/work/toptal/([^/]+)")
  if toptal then
    return toptal
  end

  return nil
end

wezterm.on("update-status", function(window, pane)
  -- local domain = pane:get_domain_name()
  -- local title = pane:get_title()
  -- local cwd = pane:get_current_working_dir()
  -- local proc = pane:get_foreground_process_info()

  -- -- Create a string with the full breakdown
  -- local info = string.format(
  --   "\n--- PANE SNAPSHOT ---\n" ..
  --   "Title:    %s\n" ..
  --   "Domain:   %s\n" ..
  --   "CWD:      %s\n" ..
  --   "ProcName: %s\n" ..
  --   "Args:     %s\n" ..
  --   "---------------------",
  --   title or "nil",
  --   domain or "nil",
  --   (cwd and cwd.file_path) or "nil",
  --   (proc and proc.name) or "nil",
  --   (proc and proc.argv and table.concat(proc.argv, " ")) or "none"
  -- )

  -- -- This will print to your debug overlay (Cmd+Shift+L)
  -- wezterm.log_info(info)

  local cwd_uri = pane:get_current_working_dir()
  if not cwd_uri then
    return
  end

  local cwd = cwd_uri.file_path or tostring(cwd_uri)
  local project = extract_project_from_path(cwd)

  local tab = window:active_tab()

  if project then
    -- set project name
    tab:set_title(project)
  else
    -- clear custom title (fallback to default numbering)
    tab:set_title("")
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
    { key = 'd', mods = 'LEADER', action = wezterm.action.ShowDebugOverlay},
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

    -- Shift Enter for Claude Code
    { key = 'Return', mods = 'SHIFT', action = act.SendString '\n' },
    { key = 'Return', mods = 'CMD', action = act.SendString '\n' },

    -- Copy/Paste (native macOS)
    { key = 'c', mods = 'CMD', action = act.CopyTo 'Clipboard' },
    { key = 'v', mods = 'CMD', action = act.PasteFrom 'Clipboard' },

    {
      key = "LeftArrow",
      mods = "OPT",
      action = wezterm.action.SendKey {
        key = "b",
        mods = "ALT",
      },
    },
    {
      key = "RightArrow",
      mods = "OPT",
      action = wezterm.action.SendKey {
        key = "f",
        mods = "ALT",
      },
    },
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
