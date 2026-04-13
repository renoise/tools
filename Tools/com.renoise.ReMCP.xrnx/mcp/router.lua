-- mcp/router.lua
-- MCP protocol handler and tool registry.
-- Tools are loaded from the tools/ directory. Each file must return an array
-- of tool definition tables: { name, description, inputSchema, handler }

local json = require("mcp.json")

local M = {}
M.tools = {}
M.protocol_version = "2025-11-25"

local function sanitize_schema(schema)
  if type(schema) ~= "table" then
    return { type = "object", properties = {} }
  end

  local out = {}
  for k, v in pairs(schema) do
    if k == "required" and type(v) == "table" and next(v) == nil then
      -- Empty required arrays are often authored as {} in Lua, which gets
      -- encoded as a JSON object. Omitting "required" is equivalent.
    elseif type(v) == "table" then
      out[k] = sanitize_schema(v)
    else
      out[k] = v
    end
  end
  return out
end

-- Register a single tool definition
function M.register(tool)
  assert(type(tool.name) == "string", "tool.name must be a string")
  assert(type(tool.handler) == "function", "tool.handler must be a function")
  M.tools[tool.name] = tool
end

-- Load all *.lua files from the tools/ subdirectory.
-- base_path should be renoise.tool().bundle_path (ends with path separator).
function M.load_tools_dir(base_path)
  local tools_dir = base_path .. "tools"
  local cmd
  if package.config:sub(1, 1) == '\\' then
    cmd = string.format('dir /b "%s\\*.lua" 2>nul', tools_dir)
  else
    cmd = string.format('ls "%s/"*.lua 2>/dev/null', tools_dir)
  end

  local names = {}
  local pipe = io.popen(cmd)
  if pipe then
    for line in pipe:lines() do
      -- Extract filename without extension and without directory prefix
      local name = line:match("([^/\\]+)%.lua$")
      if name and name ~= "" then
        names[#names + 1] = name
      end
    end
    pipe:close()
  end

  local loaded, errors = 0, {}
  for _, name in ipairs(names) do
    -- Clear any previously cached version so hot-reload works
    package.loaded["tools." .. name] = nil
    local ok, result = pcall(require, "tools." .. name)
    if ok and type(result) == "table" then
      for _, tool in ipairs(result) do
        if type(tool) == "table" and tool.name and tool.handler then
          M.register(tool)
          loaded = loaded + 1
        end
      end
    else
      errors[#errors + 1] = name .. ": " .. tostring(result)
    end
  end
  return loaded, errors
end

-- Build the tools/list result array
function M.tools_list()
  local list = {}
  for _, tool in pairs(M.tools) do
    list[#list + 1] = {
      name        = tool.name,
      description = tool.description or "",
      inputSchema = sanitize_schema(tool.inputSchema),
    }
  end
  -- Sort by name for stable output
  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end

-- Dispatch a raw JSON body string, return a JSON response string or nil
-- (nil means a notification that requires no response).
function M.handle(body)
  local msg, err = json.decode(body)
  if not msg then
    return json.encode({
      jsonrpc = "2.0", id = json.null,
      error = { code = -32700, message = "Parse error: " .. tostring(err) }
    })
  end

  -- Notifications have no id — acknowledge with no response
  if msg.id == nil and msg.method then
    return nil
  end

  local id     = msg.id
  local method = msg.method

  -- ping
  if method == "ping" then
    return json.encode({ jsonrpc = "2.0", id = id, result = {} })

  -- initialize
  elseif method == "initialize" then
    local params = msg.params or {}
    local client_protocol = params.protocolVersion
    local protocol = type(client_protocol) == "string" and client_protocol or M.protocol_version
    return json.encode({
      jsonrpc = "2.0", id = id,
      result = {
        protocolVersion = protocol,
        capabilities    = { tools = { listChanged = false } },
        serverInfo      = { name = "renoise-mcp", version = "1.0.0" },
      }
    })

  -- tools/list
  elseif method == "tools/list" then
    return json.encode({
      jsonrpc = "2.0", id = id,
      result  = { tools = M.tools_list() }
    })

  -- tools/call
  elseif method == "tools/call" then
    local params    = msg.params or {}
    local tool_name = params.name
    local args      = params.arguments or {}

    local tool = tool_name and M.tools[tool_name]
    if not tool then
      return json.encode({
        jsonrpc = "2.0", id = id,
        error = { code = -32601, message = "Tool not found: " .. tostring(tool_name) }
      })
    end

    local ok, result = pcall(tool.handler, args)
    if not ok then
      return json.encode({
        jsonrpc = "2.0", id = id,
        result  = {
          content = {{ type = "text", text = "Error: " .. tostring(result) }},
          isError = true,
        }
      })
    end
    return json.encode({ jsonrpc = "2.0", id = id, result = result })

  else
    return json.encode({
      jsonrpc = "2.0", id = id,
      error = { code = -32601, message = "Method not found: " .. tostring(method) }
    })
  end
end

return M
