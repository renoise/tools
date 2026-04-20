-- tools/instruments.lua
-- Instrument listing, info, and basic management.

local function text(s) return { content = {{ type = "text", text = tostring(s) }} } end
local function err(s)  return { content = {{ type = "text", text = tostring(s) }}, isError = true } end

local function song()
  local ok, s = pcall(renoise.song)
  if not ok or not s then error("No song loaded") end
  return s
end

-- Renoise instruments are 0-based in the UI but 1-based in the Lua table.
local function inst(s, idx_0)  -- idx_0 = 0-based (as shown in Renoise UI)
  local i = math.floor(tonumber(idx_0) or -1) + 1
  if i < 1 or i > #s.instruments then return nil, "instrument index out of range" end
  return s.instruments[i], nil
end

return {
  {
    name = "instruments_list",
    description = "List all instruments with their 0-based index, name, sample count and plugin info.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      local s = song()
      local lines = {}
      for i, instr in ipairs(s.instruments) do
        local plugin_info = ""
        if instr.plugin_properties.plugin_loaded then
          plugin_info = "  plugin=" .. instr.plugin_properties.plugin_device.name
        end
        lines[#lines + 1] = string.format("[%02d] %-32s  samples=%d%s",
          i - 1,
          instr.name ~= "" and instr.name or "(unnamed)",
          #instr.samples,
          plugin_info)
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "instrument_get_info",
    description = "Return detailed info for an instrument by 0-based index.",
    inputSchema = {
      type = "object",
      properties = { index = { type = "number", description = "0-based instrument index." } },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local instr, e = inst(s, args.index)
      if not instr then return err(e) end
      local lines = {
        "name:     " .. (instr.name ~= "" and instr.name or "(unnamed)"),
        "samples:  " .. tostring(#instr.samples),
        "phrases:  " .. tostring(#instr.phrases),
        "macros:   " .. tostring(#instr.macros),
      }
      if instr.plugin_properties.plugin_loaded then
        local pp = instr.plugin_properties
        lines[#lines + 1] = "plugin:   " .. pp.plugin_device.name
        lines[#lines + 1] = "plugin_alias: " .. tostring(pp.alias_instrument_index)
      end
      -- List sample names
      if #instr.samples > 0 then
        local snames = {}
        for si, smp in ipairs(instr.samples) do
          snames[#snames + 1] = string.format("  [%d] %s", si - 1,
            smp.name ~= "" and smp.name or "(unnamed)")
        end
        lines[#lines + 1] = "sample_list:\n" .. table.concat(snames, "\n")
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "instrument_set_name",
    description = "Rename an instrument by 0-based index.",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "0-based instrument index." },
        name  = { type = "string", description = "New name." },
      },
      required = { "index", "name" },
    },
    handler = function(args)
      local s = song()
      local instr, e = inst(s, args.index)
      if not instr then return err(e) end
      instr.name = tostring(args.name)
      return text(string.format("Instrument %d renamed to '%s'.", math.floor(tonumber(args.index)), args.name))
    end,
  },
  {
    name = "instrument_add",
    description = "Add a new blank instrument at the end of the instrument list.",
    inputSchema = {
      type = "object",
      properties = {
        name = { type = "string", description = "Optional name for the new instrument." },
      },
      required = {},
    },
    handler = function(args)
      local s   = song()
      local idx = #s.instruments  -- 0-based index of the new instrument
      s:insert_instrument_at(idx + 1)
      if args.name and args.name ~= "" then
        s.instruments[idx + 1].name = tostring(args.name)
      end
      return text(string.format("Instrument added at index %d.", idx))
    end,
  },
  {
    name = "instrument_set_volume",
    description = "Set the global linear volume of an instrument. 1.0 = 0 dB, 0.0 = silent.",
    inputSchema = {
      type = "object",
      properties = {
        index  = { type = "number", description = "0-based instrument index." },
        volume = { type = "number", description = "Linear volume (0.0 - ~2.0, where 2.0 ≈ +6 dB)." },
      },
      required = { "index", "volume" },
    },
    handler = function(args)
      local s = song()
      local instr, e = inst(s, args.index)
      if not instr then return err(e) end
      local v = tonumber(args.volume)
      if not v or v < 0 then return err("volume must be >= 0") end
      instr.volume = v
      return text(string.format("Instrument %d volume set to %.4f.", math.floor(tonumber(args.index)), v))
    end,
  },
  {
    name = "instrument_set_transpose",
    description = "Set the global transpose of an instrument in semitones (-120 to 120).",
    inputSchema = {
      type = "object",
      properties = {
        index     = { type = "number", description = "0-based instrument index." },
        transpose = { type = "number", description = "Transpose in semitones (-120 to 120)." },
      },
      required = { "index", "transpose" },
    },
    handler = function(args)
      local s = song()
      local instr, e = inst(s, args.index)
      if not instr then return err(e) end
      local t = math.floor(tonumber(args.transpose) or 0)
      if t < -120 or t > 120 then return err("transpose must be -120 to 120") end
      instr.transpose = t
      return text(string.format("Instrument %d transpose set to %d semitones.", math.floor(tonumber(args.index)), t))
    end,
  },
  {
    name = "sample_list",
    description = "List all samples in an instrument with their 0-based index, name, volume, panning, and frame count.",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "0-based instrument index." },
      },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local instr, e = inst(s, args.index)
      if not instr then return err(e) end
      if #instr.samples == 0 then
        return text(string.format("Instrument %d has no samples.", math.floor(tonumber(args.index))))
      end
      local lines = {}
      for si, smp in ipairs(instr.samples) do
        local buf    = smp.sample_buffer
        local frames = buf.has_sample_data and tostring(buf.number_of_frames) or "no data"
        lines[#lines + 1] = string.format("[%02d] %-28s  vol=%.2f  pan=%.2f  frames=%s",
          si - 1,
          smp.name ~= "" and smp.name or "(unnamed)",
          smp.volume, smp.panning, frames)
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "sample_set_name",
    description = "Rename a sample inside an instrument.",
    inputSchema = {
      type = "object",
      properties = {
        instrument = { type = "number", description = "0-based instrument index." },
        sample     = { type = "number", description = "0-based sample index." },
        name       = { type = "string", description = "New sample name." },
      },
      required = { "instrument", "sample", "name" },
    },
    handler = function(args)
      local s = song()
      local instr, e = inst(s, args.instrument)
      if not instr then return err(e) end
      local si = math.floor(tonumber(args.sample) or -1) + 1
      if si < 1 or si > #instr.samples then return err("sample index out of range") end
      instr.samples[si].name = tostring(args.name)
      return text(string.format("Sample %d in instrument %d renamed to '%s'.",
        si - 1, math.floor(tonumber(args.instrument)), args.name))
    end,
  },
  {
    name = "sample_add",
    description = "Add a new empty sample slot to an instrument.",
    inputSchema = {
      type = "object",
      properties = {
        instrument = { type = "number", description = "0-based instrument index." },
        name       = { type = "string", description = "Optional name for the new sample." },
      },
      required = { "instrument" },
    },
    handler = function(args)
      local s = song()
      local instr, e = inst(s, args.instrument)
      if not instr then return err(e) end
      local idx = #instr.samples  -- 0-based index of the new sample
      instr:insert_sample_at(idx + 1)
      if args.name and args.name ~= "" then
        instr.samples[idx + 1].name = tostring(args.name)
      end
      return text(string.format("Sample added at index %d in instrument %d.",
        idx, math.floor(tonumber(args.instrument))))
    end,
  },
  {
    name = "sample_remove",
    description = "Remove a sample slot from an instrument by 0-based sample index.",
    inputSchema = {
      type = "object",
      properties = {
        instrument = { type = "number", description = "0-based instrument index." },
        sample     = { type = "number", description = "0-based sample index." },
      },
      required = { "instrument", "sample" },
    },
    handler = function(args)
      local s = song()
      local instr, e = inst(s, args.instrument)
      if not instr then return err(e) end
      if #instr.samples <= 1 then return err("cannot remove last sample") end
      local si = math.floor(tonumber(args.sample) or -1) + 1
      if si < 1 or si > #instr.samples then return err("sample index out of range") end
      instr:delete_sample_at(si)
      return text(string.format("Sample %d removed from instrument %d.",
        si - 1, math.floor(tonumber(args.instrument))))
    end,
  },
  {
    name = "instrument_remove",
    description = "Remove an instrument by 0-based index. Must have at least one instrument left.",
    inputSchema = {
      type = "object",
      properties = { index = { type = "number", description = "0-based instrument index." } },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      if #s.instruments <= 1 then return err("cannot remove last instrument") end
      local i = math.floor(tonumber(args.index) or -1)
      if i < 0 or i >= #s.instruments then return err("instrument index out of range") end
      s:delete_instrument_at(i + 1)
      return text(string.format("Instrument %d removed.", i))
    end,
  },
}
