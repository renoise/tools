-- main.lua
-- ReMCP — Renoise MCP Server
-- Entry point loaded by Renoise when the tool is installed.
--
-- Architecture overview:
--   main.lua        registers menu/keybinding, wires up cleanup
--   mcp/json.lua    JSON encoder/decoder (pure Lua, no external deps)
--   mcp/router.lua  MCP protocol handler, tool registry
--   mcp/server.lua  HTTP/TCP server using renoise.Socket
--   tools/*.lua     Drop new .lua files here to add more MCP tools
--   ui/dialog.lua   Control panel (start/stop, log, Claude setup)
--
-- MCP transport: Streamable HTTP (POST /mcp)
-- Default port:  19714

-- ── Menu entry ─────────────────────────────────────────────────────────────

renoise.tool():add_menu_entry {
  name   = "Main Menu:Tools:Renoise MCP...",
  invoke = function() require("ui.dialog").show() end,
}

-- Optionally also accessible from the Pattern Editor context menu
renoise.tool():add_menu_entry {
  name   = "Pattern Editor:Renoise MCP...",
  invoke = function() require("ui.dialog").show() end,
}

-- ── Keybinding (optional) ──────────────────────────────────────────────────

renoise.tool():add_keybinding {
  name    = "Global:Tools:Toggle ReMCP Dialog",
  invoke  = function() require("ui.dialog").show() end,
}

-- Note: Renoise automatically closes all sockets when the application exits,
-- so no explicit cleanup hook is needed here. The server can also be stopped
-- manually from the ReMCP dialog before quitting.
