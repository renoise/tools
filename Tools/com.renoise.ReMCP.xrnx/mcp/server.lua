-- mcp/server.lua
-- HTTP/1.1 TCP server using renoise.Socket for MCP Streamable HTTP transport.
--
-- receive() is non-functional inside socket callbacks (reentrancy blocks the
-- event loop). Three complementary paths are tried in order:
--
--   A) socket_message callback  — data delivered by the event loop
--      Key: uses peer_address:peer_port string, not socket userdata identity,
--      because Renoise may wrap the same socket in different Lua objects.
--
--   B) Timer polling (100 ms)  — receive("*line", 10) with non-zero timeout
--      read from outside the socket event loop.
--
-- Whichever path fires first wins; the other is a no-op (state == "done").

local router = require("mcp.router")

local M = {}
M.running    = false
M.socket_srv = nil
M.clients    = {}   -- key: "peer_addr:peer_port" string  -> info table
M.client_order = {} -- FIFO keys for unmatched socket_message fallback routing
M.fallback_raw  = "" -- Raw buffer when socket_message arrives before/without a mapped client
M.needs_restart = false  -- set by socket_error; triggers auto-restart in safe_poll_clients
M.port       = 19714
M.log_fn     = nil

-- ============================================================
-- Helpers
-- ============================================================

local function log(msg)
  if M.log_fn then M.log_fn(msg) end
end

local LOG_PREVIEW_MAX = 300

local function log_payload(prefix, payload)
  local txt = tostring(payload or "")
  local n = #txt
  if n <= LOG_PREVIEW_MAX then
    log(string.format("%s (%d B) %s", prefix, n, txt))
  else
    log(string.format(
      "%s (%d B, truncated to %d B) %s [truncated]",
      prefix, n, LOG_PREVIEW_MAX, txt:sub(1, LOG_PREVIEW_MAX)
    ))
  end
end

local function peer_key(sock)
  return tostring(sock.peer_address or "?") .. ":" .. tostring(sock.peer_port or 0)
end

local function close_sock(sock)
  pcall(function()
    if sock.is_open then sock:close() end
  end)
end

local function queue_remove(key)
  for i = 1, #M.client_order do
    if M.client_order[i] == key then
      table.remove(M.client_order, i)
      return
    end
  end
end

local function remove_client(key, close_it)
  local info = M.clients[key]
  if not info then return end
  M.clients[key] = nil
  queue_remove(key)
  if close_it then close_sock(info.sock) end
end

local function first_pending_client()
  for i = 1, #M.client_order do
    local key = M.client_order[i]
    local info = M.clients[key]
    if info and info.state ~= "done" then
      return key, info
    end
  end
  return nil, nil
end

-- ============================================================
-- HTTP response builders
-- ============================================================

local function http_ok(ct, body)
  return "HTTP/1.1 200 OK\r\nContent-Type: " .. ct
    .. "\r\nContent-Length: " .. #body
    .. "\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n" .. body
end
local function http_202()
  return "HTTP/1.1 202 Accepted\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
end
local function http_cors()
  return "HTTP/1.1 204 No Content\r\n"
    .. "Access-Control-Allow-Origin: *\r\n"
    .. "Access-Control-Allow-Methods: POST, GET, OPTIONS\r\n"
    .. "Access-Control-Allow-Headers: Content-Type, Accept, Mcp-Session-Id\r\n"
    .. "Connection: close\r\n\r\n"
end
local function http_404()
  local b = '{"error":"not found"}'
  return "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\n"
    .. "Content-Length: " .. #b .. "\r\nConnection: close\r\n\r\n" .. b
end

-- ============================================================
-- Request dispatcher
-- ============================================================

local function dispatch(sock, method, path, body)
  if method == "OPTIONS" then sock:send(http_cors()) return end
  if method == "GET" and path == "/health" then
    sock:send(http_ok("application/json", '{"status":"ok","server":"renoise-mcp"}'))
    return
  end
  if method == "POST" and path:match("^/mcp") then
    if #body == 0 then sock:send(http_202()) return end
    log_payload(">>", body)
    local rok, resp = pcall(router.handle, body)
    if not rok then
      log("router error: " .. tostring(resp))
      sock:send(http_ok("application/json",
        '{"jsonrpc":"2.0","id":null,"error":{"code":-32603,"message":"Internal error"}}'))
      return
    end
    if resp then
      log_payload("<<", resp)
      sock:send(http_ok("application/json", resp))
    else
      sock:send(http_202())
    end
    return
  end
  sock:send(http_404())
end

-- ============================================================
-- Raw-buffer HTTP parser (used by path A)
-- Returns method, path, body on a complete request; nil otherwise.
-- ============================================================

local function parse_raw(raw)
  local p1 = raw:find("\r\n\r\n", 1, true)
  local p2 = raw:find("\n\n",     1, true)
  local hend, tlen
  if p1 and (not p2 or p1 <= p2) then hend, tlen = p1, 4
  elseif p2 then                       hend, tlen = p2, 2
  else return nil end

  local hdr     = raw:sub(1, hend - 1)
  local bstart  = hend + tlen
  local cl      = tonumber(hdr:match("[Cc]ontent%-[Ll]ength:%s*(%d+)")) or 0
  if #raw < bstart + cl - 1 then return nil end

  local method, path = hdr:match("^(%u+)%s+([^%s]+)%s+HTTP/")
  if not method then return nil end
  local bend = bstart + cl - 1
  return method, path, raw:sub(bstart, bend), bend
end

-- ============================================================
-- Path A: socket_message callback
-- Uses peer_key string so object identity doesn't matter.
-- ============================================================

local function on_socket_message(sock, data)
  if not M.running or not data or #data == 0 then return end

  local key  = peer_key(sock)
  log("socket_message [" .. key .. "] len=" .. #data)

  local target_key = key
  local info = M.clients[target_key]
  if not info or info.state == "done" then
    target_key, info = first_pending_client()
  end

  if info and info.state ~= "done" then
    info.raw = info.raw .. data

    local method, path, body = parse_raw(info.raw)
    if method then
      -- Only mark done once we have a complete request.
      info.state = "done"
      local ok, e = pcall(dispatch, sock, method, path, body)
      if not ok then log("dispatch error: " .. tostring(e)) end
      -- Do NOT close info.sock or remove M.clients here.
      -- Closing sockets inside socket callbacks can disrupt Renoise's event loop.
      -- poll_clients runs on the next timer tick and safely closes/removes info.sock.
    end
    return
  end

  -- Last fallback for unexpected callback ordering: accumulate and parse with
  -- a standalone raw buffer so split packets are not dropped.
  M.fallback_raw = M.fallback_raw .. data
  local method, path, body, bend = parse_raw(M.fallback_raw)
  if method then
    local ok, e = pcall(dispatch, sock, method, path, body)
    if not ok then log("dispatch error: " .. tostring(e)) end
    M.fallback_raw = M.fallback_raw:sub(bend + 1)
    -- Keep only the latest bytes if parser did not fully consume malformed data.
    if #M.fallback_raw > 65536 then
      M.fallback_raw = M.fallback_raw:sub(-8192)
    end
  end
end

-- ============================================================
-- Path B: timer polling (100 ms interval, 10 ms read timeout)
-- Reads outside the socket event loop; non-zero timeout may work
-- where timeout=0 and callback-context reads both fail.
-- ============================================================

local function poll_clients()
  local dead     = {}  -- remove only (normal completion / already closed by remote)
  local dead_err = {}  -- remove + close (read/protocol errors)

  for key, info in pairs(M.clients) do
    -- Safely read is_open: accessing a closed socket can throw a runtime error.
    local sock_open = false
    pcall(function() sock_open = info.sock.is_open end)

    if info.state == "done" then
      -- Request handled; HTTP client will close its end (Connection: close header).
      -- Do NOT call close() here — closing info.sock can kill the server socket.
      dead[#dead + 1] = key
    elseif not sock_open then
      -- Remote already closed the connection; nothing to close on our side.
      dead[#dead + 1] = key
    else
      -- Path B: timer-based read (fallback when socket_message did not fire)
      if info.state == "headers" then
        while true do
          local line, err = info.sock:receive("*line", 10)
          if not line then
            if err and err ~= "timeout" then
              log("poll: header read error: " .. tostring(err))
              dead_err[#dead_err + 1] = key
            end
            break
          end
          log("poll: got header line: " .. line:sub(1, 80))
          line = line:gsub("\r$", "")
          if line == "" then
            info.state = "body"
            info.clen  = tonumber(info.hdrs:match("[Cc]ontent%-[Ll]ength:%s*(%d+)")) or 0
            break
          else
            info.hdrs = info.hdrs .. line .. "\r\n"
          end
        end
      end

      if info.state == "body" then
        local need = info.clen - #info.body
        while need > 0 do
          local chunk, err = info.sock:receive(need, 10)
          if chunk and #chunk > 0 then
            info.body = info.body .. chunk
            need = info.clen - #info.body
          else
            if err and err ~= "timeout" then dead_err[#dead_err + 1] = key end
            break
          end
        end

        if info.clen == 0 or #info.body >= info.clen then
          info.state = "done"
          local method, path = info.hdrs:match("^(%u+)%s+([^%s]+)%s+HTTP/")
          if method then
            log("poll: dispatching " .. method .. " " .. path)
            pcall(dispatch, info.sock, method, path, info.body)
          end
          dead[#dead + 1] = key
        end
      end
    end
  end

  for _, key in ipairs(dead)     do remove_client(key, false) end
  for _, key in ipairs(dead_err) do remove_client(key, true)  end
end

-- ============================================================
-- Socket callbacks (extracted so restart_server can reuse them)
-- ============================================================

local cb_socket_accepted = function(sock)
  local ok, err = pcall(function()
    if not M.running then close_sock(sock) return end
    local key = peer_key(sock)
    -- Rare but possible if the same key is reused quickly by the OS.
    remove_client(key, true)
    log("Client connected: " .. key)
    M.clients[key] = {
      sock  = sock,
      state = "headers",
      hdrs  = "",
      body  = "",
      clen  = 0,
      raw   = "",
    }
    M.client_order[#M.client_order + 1] = key
  end)
  if not ok then
    log("socket_accepted handler error: " .. tostring(err))
    close_sock(sock)
  end
end

local cb_socket_message = function(sock, data)
  local ok, err = pcall(on_socket_message, sock, data)
  if not ok then
    log("socket_message handler error: " .. tostring(err))
  end
end

local function make_notifier()
  return {
    socket_error = function(msg)
      log("Socket error: " .. tostring(msg))
      M.needs_restart = true
    end,
    socket_accepted = cb_socket_accepted,
    socket_message  = cb_socket_message,
  }
end

-- ============================================================
-- Auto-restart: recreate the server after a socket_error
-- ============================================================

local function restart_server()
  log("Server stopped unexpectedly; restarting on port " .. M.port .. "...")
  M.needs_restart = false
  M.clients       = {}
  M.client_order  = {}
  M.fallback_raw  = ""
  -- Stash and nil the reference first so nothing else touches the old socket.
  local old = M.socket_srv
  M.socket_srv = nil
  -- stop() halts callbacks; close() releases the OS port binding.
  -- Both are pcall'd: the socket may already be dead.
  pcall(function() old:stop()  end)
  pcall(function() old:close() end)
  local srv, err = renoise.Socket.create_server(M.port, renoise.Socket.PROTOCOL_TCP)
  if srv then
    M.socket_srv = srv
    srv:run(make_notifier())
    log("Server restarted on http://localhost:" .. M.port .. "/mcp")
  else
    log("Failed to restart: " .. tostring(err))
    M.running = false
  end
end

-- ============================================================

local function safe_poll_clients()
  if M.running and M.socket_srv then
    -- Wrap is_running: accessing a dead socket object can throw.
    local srv_running = true
    pcall(function() srv_running = M.socket_srv.is_running end)
    if M.needs_restart or not srv_running then
      restart_server()
    end
  end
  local ok, err = pcall(poll_clients)
  if not ok then
    log("poll_clients error: " .. tostring(err))
  end
end

-- ============================================================
-- Public API
-- ============================================================

function M.start(port, log_fn)
  if M.running then return false, "server already running" end
  M.log_fn = log_fn
  local new_port = port or 19714

  if M.socket_srv and new_port == M.port then
    M.running = true
    log("MCP server resumed on http://localhost:" .. M.port .. "/mcp")
    return true
  end

  if M.socket_srv then
    M.socket_srv:stop()
    M.socket_srv    = nil
    M.clients       = {}
    M.client_order  = {}
    M.fallback_raw  = ""
    M.needs_restart = false
  end

  M.port          = new_port
  M.clients       = {}
  M.client_order  = {}
  M.fallback_raw  = ""
  M.needs_restart = false

  local srv, err = renoise.Socket.create_server(M.port, renoise.Socket.PROTOCOL_TCP)
  if not srv then return false, tostring(err) end
  M.socket_srv = srv

  srv:run(make_notifier())

  if not renoise.tool():has_timer(safe_poll_clients) then
    renoise.tool():add_timer(safe_poll_clients, 100)
  end

  M.running = true
  log("MCP server listening on http://localhost:" .. M.port .. "/mcp")
  return true
end

function M.stop()
  if not M.running then return end
  for _, info in pairs(M.clients) do close_sock(info.sock) end
  M.clients = {}
  M.client_order = {}
  M.fallback_raw = ""
  M.running = false
  log("MCP server paused (port " .. M.port .. " still reserved)")
end

function M.client_count()
  local n = 0
  for _ in pairs(M.clients) do n = n + 1 end
  return n
end

return M
