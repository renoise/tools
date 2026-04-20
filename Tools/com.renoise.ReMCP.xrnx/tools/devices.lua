-- tools/devices.lua
-- DSP FX chain management: list, add, remove, move devices on tracks.
-- Device indices are 1-based. Index 1 is always the non-removable Mixer device.

local function text(s) return { content = {{ type = "text", text = tostring(s) }} } end
local function err(s)  return { content = {{ type = "text", text = tostring(s) }}, isError = true } end

local function song()
  local ok, s = pcall(renoise.song)
  if not ok or not s then error("No song loaded") end
  return s
end

local function get_track(s, index)
  local i = math.floor(tonumber(index) or 0)
  if i < 1 or i > #s.tracks then return nil, nil, "invalid track index" end
  return s.tracks[i], i, nil
end

return {
  {
    name = "plugins_search",
    description = [[Search for available plugins across both track FX devices and instrument plugins.
Returns matching paths grouped by category (fx / instrument).
filter: case-insensitive substring (e.g. "ozone", "reverb", "VST3"). Required.
type: "fx" = track FX only, "instrument" = instrument plugins only, "all" = both (default).]],
    inputSchema = {
      type = "object",
      properties = {
        filter = { type = "string", description = "Case-insensitive substring to search for." },
        type   = { type = "string", description = '"fx", "instrument", or "all" (default).' },
      },
      required = { "filter" },
    },
    handler = function(args)
      local s      = song()
      local filter = tostring(args.filter or ""):lower()
      local mode   = tostring(args.type or "all"):lower()

      local results = {}

      -- ── Track FX devices ────────────────────────────────────────────────
      if mode == "all" or mode == "fx" then
        -- available_devices is identical across all tracks; use track 1
        if #s.tracks > 0 then
          for _, path in ipairs(s.tracks[1].available_devices) do
            if filter == "" or path:lower():find(filter, 1, true) then
              results[#results + 1] = "fx         " .. path
            end
          end
        end
      end

      -- ── Instrument plugins ───────────────────────────────────────────────
      if mode == "all" or mode == "instrument" then
        if #s.instruments > 0 then
          local ok, plugins = pcall(function()
            return s.instruments[1].plugin_properties.available_plugins
          end)
          if ok and plugins then
            for _, path in ipairs(plugins) do
              if filter == "" or path:lower():find(filter, 1, true) then
                results[#results + 1] = "instrument " .. path
              end
            end
          end
        end
      end

      if #results == 0 then
        return text(string.format("No plugins found matching '%s'.", args.filter))
      end
      return text(table.concat(results, "\n"))
    end,
  },
  {
    name = "track_devices_list",
    description = "List all DSP devices in a track's FX chain. Index 1 is always the non-removable Mixer device.",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "1-based track index." },
      },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local t, _, e = get_track(s, args.index)
      if not t then return err(e) end
      local lines = {}
      for di, dev in ipairs(t.devices) do
        lines[#lines + 1] = string.format("[%d] %-32s  active=%-5s  path=%s",
          di,
          dev.name,
          tostring(dev.is_active),
          dev.device_path)
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "track_devices_available",
    description = "List device paths that can be inserted on a track, with optional case-insensitive substring filter.",
    inputSchema = {
      type = "object",
      properties = {
        index  = { type = "number", description = "1-based track index." },
        filter = { type = "string", description = "Optional substring to filter results." },
      },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local t, _, e = get_track(s, args.index)
      if not t then return err(e) end
      local filter = args.filter and tostring(args.filter):lower() or nil
      local lines  = {}
      for _, path in ipairs(t.available_devices) do
        if not filter or path:lower():find(filter, 1, true) then
          lines[#lines + 1] = path
        end
      end
      if #lines == 0 then return text("No matching devices found.") end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "track_device_add",
    description = "Insert a DSP device into a track's FX chain by device path. Use track_devices_available to find valid paths.",
    inputSchema = {
      type = "object",
      properties = {
        index       = { type = "number", description = "1-based track index." },
        device_path = { type = "string", description = "Device path from track_devices_available." },
        position    = { type = "number", description = "1-based insert position in the FX chain (default: append after last device)." },
      },
      required = { "index", "device_path" },
    },
    handler = function(args)
      local s = song()
      local t, i, e = get_track(s, args.index)
      if not t then return err(e) end
      -- position 1 = Mixer (protected); valid insert range is [2, #devices+1]
      local pos = math.floor(tonumber(args.position) or #t.devices + 1)
      pos = math.max(2, math.min(pos, #t.devices + 1))
      t:insert_device_at(tostring(args.device_path), pos)
      return text(string.format("Device '%s' inserted at position %d on track %d.",
        args.device_path, pos, i))
    end,
  },
  {
    name = "track_device_remove",
    description = "Remove a DSP device from a track's FX chain by 1-based device index. Index 1 (the Mixer) cannot be removed.",
    inputSchema = {
      type = "object",
      properties = {
        index        = { type = "number", description = "1-based track index." },
        device_index = { type = "number", description = "1-based device index (must be >= 2)." },
      },
      required = { "index", "device_index" },
    },
    handler = function(args)
      local s = song()
      local t, ti, e = get_track(s, args.index)
      if not t then return err(e) end
      local di = math.floor(tonumber(args.device_index) or 0)
      if di < 2             then return err("device_index must be >= 2 (index 1 is the Mixer and cannot be removed)") end
      if di > #t.devices    then return err("device_index out of range") end
      local name = t.devices[di].name
      t:delete_device_at(di)
      return text(string.format("Device '%s' (index %d) removed from track %d.", name, di, ti))
    end,
  },
  {
    name = "track_device_move",
    description = "Swap the positions of two DSP devices within a track's FX chain. Neither index may be 1 (the Mixer).",
    inputSchema = {
      type = "object",
      properties = {
        index   = { type = "number", description = "1-based track index." },
        device1 = { type = "number", description = "1-based index of the first device (must be >= 2)." },
        device2 = { type = "number", description = "1-based index of the second device (must be >= 2)." },
      },
      required = { "index", "device1", "device2" },
    },
    handler = function(args)
      local s = song()
      local t, ti, e = get_track(s, args.index)
      if not t then return err(e) end
      local d1 = math.floor(tonumber(args.device1) or 0)
      local d2 = math.floor(tonumber(args.device2) or 0)
      if d1 < 2               then return err("device1 must be >= 2 (index 1 is the Mixer)") end
      if d2 < 2               then return err("device2 must be >= 2 (index 1 is the Mixer)") end
      if d1 == d2             then return err("device1 and device2 must be different") end
      if d1 > #t.devices or d2 > #t.devices then return err("device index out of range") end
      t:swap_devices_at(d1, d2)
      return text(string.format("Devices %d ('%s') and %d ('%s') swapped on track %d.",
        d1, t.devices[d1].name, d2, t.devices[d2].name, ti))
    end,
  },
  {
    name = "track_device_set_active",
    description = "Enable or bypass a DSP device in a track's FX chain.",
    inputSchema = {
      type = "object",
      properties = {
        index        = { type = "number",  description = "1-based track index." },
        device_index = { type = "number",  description = "1-based device index." },
        active       = { type = "boolean", description = "true = active/enabled, false = bypassed." },
      },
      required = { "index", "device_index", "active" },
    },
    handler = function(args)
      local s = song()
      local t, ti, e = get_track(s, args.index)
      if not t then return err(e) end
      local di = math.floor(tonumber(args.device_index) or 0)
      if di < 1 or di > #t.devices then return err("device_index out of range") end
      t.devices[di].is_active = args.active and true or false
      return text(string.format("Device %d ('%s') on track %d set to %s.",
        di, t.devices[di].name, ti, args.active and "active" or "bypassed"))
    end,
  },
  {
    name = "track_device_get_params",
    description = "List all parameters of a DSP device with their current values.",
    inputSchema = {
      type = "object",
      properties = {
        index        = { type = "number", description = "1-based track index." },
        device_index = { type = "number", description = "1-based device index." },
      },
      required = { "index", "device_index" },
    },
    handler = function(args)
      local s = song()
      local t, _, e = get_track(s, args.index)
      if not t then return err(e) end
      local di = math.floor(tonumber(args.device_index) or 0)
      if di < 1 or di > #t.devices then return err("device_index out of range") end
      local dev   = t.devices[di]
      local lines = { string.format("Device: %s", dev.name) }
      for pi, param in ipairs(dev.parameters) do
        lines[#lines + 1] = string.format("  [%02d] %-32s  value=%-10s  range=(%.4f - %.4f)",
          pi,
          param.name,
          param.value_string,
          param.value_min,
          param.value_max)
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "track_device_set_param",
    description = "Set a parameter value on a DSP device by 1-based parameter index.",
    inputSchema = {
      type = "object",
      properties = {
        index        = { type = "number", description = "1-based track index." },
        device_index = { type = "number", description = "1-based device index." },
        param_index  = { type = "number", description = "1-based parameter index." },
        value        = { type = "number", description = "New parameter value (within the parameter's min/max range)." },
      },
      required = { "index", "device_index", "param_index", "value" },
    },
    handler = function(args)
      local s = song()
      local t, ti, e = get_track(s, args.index)
      if not t then return err(e) end
      local di = math.floor(tonumber(args.device_index) or 0)
      if di < 1 or di > #t.devices then return err("device_index out of range") end
      local dev = t.devices[di]
      local pi  = math.floor(tonumber(args.param_index) or 0)
      if pi < 1 or pi > #dev.parameters then return err("param_index out of range") end
      local param = dev.parameters[pi]
      local v     = tonumber(args.value)
      if not v then return err("value must be a number") end
      v = math.max(param.value_min, math.min(param.value_max, v))
      param.value = v
      return text(string.format("Track %d device %d ('%s') param %d ('%s') set to %.6f.",
        ti, di, dev.name, pi, param.name, v))
    end,
  },
}
