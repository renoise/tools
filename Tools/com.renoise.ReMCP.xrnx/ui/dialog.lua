-- ui/dialog.lua
-- Main control panel for ReMCP.
-- Shows server status, start/stop, port picker, live log, and Claude config.

local server = require("mcp.server")
local router = require("mcp.router")

local M = {}

local dlg        = nil   -- renoise Dialog
local vb         = nil   -- ViewBuilder
local log_lines  = {}
local MAX_LOG    = 80
local base_path  = nil   -- set on first show()

-- ============================================================
-- Logging
-- ============================================================

local function add_log(msg)
  local ts = os.date("%H:%M:%S")
  log_lines[#log_lines + 1] = string.format("[%s] %s", ts, msg)
  if #log_lines > MAX_LOG then table.remove(log_lines, 1) end
  if vb and vb.views["log_area"] then
    vb.views["log_area"].text = table.concat(log_lines, "\n")
    vb.views["log_area"]:scroll_to_last_line()
  end
end

-- ============================================================
-- Config text
-- ============================================================

local function config_text(port)
  return string.format([[
=== Claude Desktop Configuration ===

Edit  ~/Library/Application Support/Claude/claude_desktop_config.json
and add the "renoise" entry inside "mcpServers":

{
  "mcpServers": {
    "renoise": {
      "type": "streamable-http",
      "url": "http://localhost:%d/mcp"
    }
  }
}

If your Claude Desktop does not yet support streamable-http,
use the mcp-remote bridge (requires Node.js / npx):

{
  "mcpServers": {
    "renoise": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://localhost:%d/mcp"]
    }
  }
}

After saving, fully quit and relaunch Claude Desktop.
The "renoise" server will appear in the connectors list.
]], port, port)
end

-- ============================================================
-- UI helpers
-- ============================================================

local function tool_count()
  local n = 0
  for _ in pairs(router.tools) do n = n + 1 end
  return n
end

local function update_ui()
  if not vb then return end
  local running = server.running
  vb.views["status_dot"].text  = running and "●" or "○"
  vb.views["status_text"].text = running
    and string.format("Running on port %d", server.port)
    or  "Stopped"
  vb.views["toggle_btn"].text  = running and "Stop Server" or "Start Server"
  vb.views["tool_count"].text  = string.format("%d tools loaded", tool_count())
end

local function do_start(port)
  local ok, e = server.start(port, add_log)
  if not ok then
    add_log("ERROR: " .. tostring(e))
    renoise.app():show_warning("ReMCP: Could not start server.\n" .. tostring(e))
  end
  update_ui()
end

local function do_stop()
  server.stop()
  update_ui()
end

local function do_reload()
  local was_running = server.running
  local active_port = server.port

  if was_running then
    server.stop()
  end

  -- Clear cached MCP/tool modules so files on disk are re-read
  package.loaded["mcp.server"] = nil
  package.loaded["mcp.router"] = nil
  package.loaded["mcp.json"]   = nil
  for k in pairs(package.loaded) do
    if k:match("^tools%.") then package.loaded[k] = nil end
  end

  router = require("mcp.router")
  server = require("mcp.server")

  local n, errs = router.load_tools_dir(base_path)
  add_log(string.format("Reloaded MCP core + %d tools.", n))
  for _, e in ipairs(errs) do add_log("  WARN: " .. e) end

  if was_running then
    local ok, e = server.start(active_port, add_log)
    if not ok then
      add_log("ERROR: " .. tostring(e))
      renoise.app():show_warning("ReMCP: Could not restart server.\n" .. tostring(e))
    end
  end

  update_ui()
end

-- ============================================================
-- Build dialog content
-- ============================================================

local function build_dialog(port)
  vb = renoise.ViewBuilder()

  local STATUS_W = 360

  -- ---- Header ------------------------------------------------
  local header = vb:row {
    margin  = 4,
    spacing = 6,
    vb:text { text = "Renoise MCP Server", font = "bold", width = 200 },
    vb:text { id = "tool_count", text = "0 tools", width = 120, align = "right" },
  }

  -- ---- Status row -------------------------------------------
  local status_row = vb:row {
    margin  = 4,
    spacing = 4,
    vb:text { id = "status_dot",  text = "○", font = "bold", width = 16 },
    vb:text { id = "status_text", text = "Stopped", width = STATUS_W },
  }

  -- ---- Controls row -----------------------------------------
  local controls = vb:row {
    margin  = 4,
    spacing = 6,
    vb:text  { text = "Port:", width = 32 },
    vb:valuebox {
      id    = "port_box",
      value = port,
      min   = 1024,
      max   = 65535,
      notifier = function(v)
        if vb.views["cfg_area"] then
          vb.views["cfg_area"].text = config_text(v)
        end
      end,
    },
    vb:button {
      id       = "toggle_btn",
      text     = "Start Server",
      width    = 110,
      notifier = function()
        if server.running then
          do_stop()
        else
          do_start(vb.views["port_box"].value)
        end
      end,
    },
    vb:button {
      text     = "Reload Tools",
      width    = 100,
      notifier = do_reload,
    },
  }

  -- ---- Tab switcher -----------------------------------------
  local tab_btns = vb:row {
    margin  = 4,
    spacing = 2,
    vb:button {
      text     = "Log",
      width    = 80,
      notifier = function()
        vb.views["log_panel"].visible = true
        vb.views["cfg_panel"].visible = false
      end,
    },
    vb:button {
      text     = "Setup",
      width    = 80,
      notifier = function()
        vb.views["log_panel"].visible = false
        vb.views["cfg_panel"].visible = true
      end,
    },
  }

  -- ---- Log panel --------------------------------------------
  local log_panel = vb:column {
    id      = "log_panel",
    visible = true,
    vb:multiline_text {
      id     = "log_area",
      text   = "",
      width  = 500,
      height = 200,
      font   = "mono",
    },
  }

  -- ---- Config panel -----------------------------------------
  local cfg_panel = vb:column {
    id      = "cfg_panel",
    visible = false,
    vb:multiline_text {
      id     = "cfg_area",
      text   = config_text(port),
      width  = 500,
      height = 200,
      font   = "mono",
    },
  }

  -- ---- Root layout ------------------------------------------
  return vb:column {
    margin  = 8,
    spacing = 4,
    header,
    status_row,
    controls,
    tab_btns,
    log_panel,
    cfg_panel,
  }
end

-- ============================================================
-- Public API
-- ============================================================

function M.show()
  -- Load tools on first open
  if not base_path then
    base_path = renoise.tool().bundle_path
    router.load_tools_dir(base_path)
  end

  local port = 19714

  if dlg and dlg.visible then
    dlg:show()
    return
  end

  local content = build_dialog(port)
  update_ui()
  dlg = renoise.app():show_custom_dialog("Renoise MCP", content)
  add_log("ReMCP ready. Click 'Start Server' to begin.")

  if not server.running then
    do_start(port)
  end
end

function M.close()
  if dlg and dlg.visible then dlg:close() end
end

return M
