-- tools/patterns.lua
-- Pattern creation, length, and note editing.
-- Pattern indices:  0-based (matching Renoise UI)
-- Track indices:    1-based (matching Renoise Lua API)
-- Line indices:     1-based (matching Renoise Lua API)
-- Instrument index: 0-based (matching Renoise UI)

local function text(s) return { content = {{ type = "text", text = tostring(s) }} } end
local function err(s)  return { content = {{ type = "text", text = tostring(s) }}, isError = true } end

local function song()
  local ok, s = pcall(renoise.song)
  if not ok or not s then error("No song loaded") end
  return s
end

-- Note value constants (from renoise.PatternLine)
local EMPTY_NOTE      = 121
local NOTE_OFF        = 120
local EMPTY_INST      = 255
local EMPTY_VOLUME    = 255
local EMPTY_PANNING   = 255
local EMPTY_DELAY     = 0
local EMPTY_FX_NUM    = 0
local EMPTY_FX_AMT    = 0

-- Note value helpers
local NOTE_NAMES = { "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-" }

local function note_to_str(v)
  if v == NOTE_OFF   then return "OFF" end
  if v == EMPTY_NOTE then return "---" end
  local oct  = math.floor(v / 12)
  local name = NOTE_NAMES[(v % 12) + 1]
  return name .. tostring(oct)
end

-- Parse "C-4", "C#4", "OFF" or "---" -> note value / NOTE_OFF / EMPTY
local function str_to_note(s)
  s = s:upper():gsub("%s", "")
  if s == "OFF" then return NOTE_OFF end
  if s == "---" or s == "" then return EMPTY_NOTE end
  -- match  [A-G][#-]?[0-9]
  local name, oct_s = s:match("^([A-G][#%-]?)(%d+)$")
  if not name then return nil, "invalid note: " .. s end
  name = name:gsub("%-", "-")  -- normalise D- -> D-
  local oct = tonumber(oct_s)
  local idx_map = {
    ["C-"]=0,["C#"]=1,["D-"]=2,["D#"]=3,["E-"]=4,
    ["F-"]=5,["F#"]=6,["G-"]=7,["G#"]=8,["A-"]=9,["A#"]=10,["B-"]=11,
    -- also accept without dash
    ["C"]=0,["D"]=2,["E"]=4,["F"]=5,["G"]=7,["A"]=9,["B"]=11,
  }
  local base = idx_map[name]
  if not base then return nil, "unknown note name: " .. name end
  return oct * 12 + base
end

return {
  {
    name = "patterns_list",
    description = "List all patterns with their 0-based index and line count.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      local s = song()
      local lines = {}
      for i, p in ipairs(s.patterns) do
        lines[#lines + 1] = string.format("[%02d] lines=%d", i - 1, p.number_of_lines)
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "pattern_get_info",
    description = "Return info (line count) for a pattern by 0-based index.",
    inputSchema = {
      type = "object",
      properties = { index = { type = "number", description = "0-based pattern index." } },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or -1) + 1
      if i < 1 or i > #s.patterns then return err("invalid pattern index") end
      local p = s.patterns[i]
      return text(string.format("pattern=%d  lines=%d  tracks=%d",
        i - 1, p.number_of_lines, #p.tracks))
    end,
  },
  {
    name = "pattern_set_length",
    description = "Set the number of lines in a pattern (1-512).",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "0-based pattern index." },
        lines = { type = "number", description = "Number of lines (1-512)." },
      },
      required = { "index", "lines" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or -1) + 1
      if i < 1 or i > #s.patterns then return err("invalid pattern index") end
      local n = math.floor(tonumber(args.lines) or 0)
      if n < 1 or n > 512 then return err("lines must be 1-512") end
      s.patterns[i].number_of_lines = n
      return text(string.format("Pattern %d length set to %d lines.", i - 1, n))
    end,
  },
  {
    name = "pattern_set_note",
    description = [[Set a single note in a pattern.
note_value: "C-4", "D#3", "OFF" (note-off), or "---" / "" to clear.
Instrument and volume are optional (omit to leave unchanged).
Pattern index: 0-based. Track index: 1-based. Line index: 1-based.]],
    inputSchema = {
      type = "object",
      properties = {
        pattern   = { type = "number", description = "0-based pattern index." },
        track     = { type = "number", description = "1-based track index." },
        line      = { type = "number", description = "1-based line index." },
        column    = { type = "number", description = "1-based note column (default 1)." },
        note      = { type = "string", description = 'Note: "C-4", "D#3", "OFF", "---".' },
        instrument= { type = "number", description = "0-based instrument index (optional)." },
        volume    = { type = "number", description = "Volume 0x00-0x7F, or 0xFF = none (optional)." },
        panning   = { type = "number", description = "Panning 0x00-0x7F, or 0xFF = none (optional)." },
        delay     = { type = "number", description = "Delay 0x00-0xFF (optional)." },
      },
      required = { "pattern", "track", "line", "note" },
    },
    handler = function(args)
      local s  = song()
      local pi = math.floor(tonumber(args.pattern) or -1) + 1
      local ti = math.floor(tonumber(args.track)   or 0)
      local li = math.floor(tonumber(args.line)    or 0)
      local ci = math.floor(tonumber(args.column)  or 1)

      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pat = s.patterns[pi]
      if ti < 1 or ti > #pat.tracks then return err("invalid track index") end
      if li < 1 or li > pat.number_of_lines then return err("invalid line index") end

      local song_track = s.tracks[ti]
      -- Expand note columns if needed
      while song_track.visible_note_columns < ci do
        song_track.visible_note_columns = song_track.visible_note_columns + 1
      end

      local nc = pat.tracks[ti]:line(li):note_column(ci)

      local nv, parse_err = str_to_note(tostring(args.note or "---"))
      if nv == nil then return err(parse_err or "invalid note") end

      nc.note_value = nv

      if args.instrument ~= nil then
        local iv = math.floor(tonumber(args.instrument) or 0)
        nc.instrument_value = iv < 0 and EMPTY_INST or iv
      end
      if args.volume ~= nil then
        nc.volume_value = math.max(0, math.min(255, math.floor(tonumber(args.volume) or EMPTY_VOLUME)))
      end
      if args.panning ~= nil then
        nc.panning_value = math.max(0, math.min(255, math.floor(tonumber(args.panning) or EMPTY_PANNING)))
      end
      if args.delay ~= nil then
        nc.delay_value = math.max(0, math.min(255, math.floor(tonumber(args.delay) or EMPTY_DELAY)))
      end

      return text(string.format("Set %s at pattern=%d track=%d line=%d col=%d",
        note_to_str(nv), pi - 1, ti, li, ci))
    end,
  },
  {
    name = "pattern_get_notes",
    description = "Return all non-empty note and effect columns in a pattern track as text.",
    inputSchema = {
      type = "object",
      properties = {
        pattern = { type = "number", description = "0-based pattern index." },
        track   = { type = "number", description = "1-based track index." },
      },
      required = { "pattern", "track" },
    },
    handler = function(args)
      local s  = song()
      local pi = math.floor(tonumber(args.pattern) or -1) + 1
      local ti = math.floor(tonumber(args.track)   or 0)

      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pat = s.patterns[pi]
      if ti < 1 or ti > #pat.tracks then return err("invalid track index") end

      local song_track = s.tracks[ti]
      local num_note_cols   = song_track.visible_note_columns
      local num_effect_cols = song_track.visible_effect_columns

      local lines = {}
      local pt = pat.tracks[ti]
      for li = 1, pat.number_of_lines do
        local line = pt:line(li)
        -- Note columns
        for ci = 1, num_note_cols do
          local nc = line:note_column(ci)
          if not nc.is_empty then
            local note = note_to_str(nc.note_value)
            local ins  = nc.instrument_value == EMPTY_INST    and ".." or string.format("%02X", nc.instrument_value)
            local vol  = nc.volume_value     == EMPTY_VOLUME  and ".." or string.format("%02X", nc.volume_value)
            local pan  = nc.panning_value    == EMPTY_PANNING and ".." or string.format("%02X", nc.panning_value)
            local dly  = nc.delay_value      == EMPTY_DELAY   and ".." or string.format("%02X", nc.delay_value)
            local fx_n = nc.effect_number_value == EMPTY_FX_NUM and ".." or nc.effect_number_string
            local fx_a = nc.effect_amount_value == EMPTY_FX_AMT and ".." or nc.effect_amount_string
            lines[#lines + 1] = string.format(
              "line=%03d note_col=%d  note=%-4s ins=%s vol=%s pan=%s dly=%s fx=%s%s",
              li, ci, note, ins, vol, pan, dly, fx_n, fx_a)
          end
        end
        -- Effect columns
        for ci = 1, num_effect_cols do
          local ec = line:effect_column(ci)
          if not ec.is_empty then
            lines[#lines + 1] = string.format(
              "line=%03d fx_col=%d  fx=%s%s",
              li, ci, ec.number_string, ec.amount_string)
          end
        end
      end
      if #lines == 0 then
        return text(string.format("Pattern %d, track %d is empty.", pi - 1, ti))
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "pattern_clear_track",
    description = "Clear all notes in a specific track of a pattern.",
    inputSchema = {
      type = "object",
      properties = {
        pattern = { type = "number", description = "0-based pattern index." },
        track   = { type = "number", description = "1-based track index." },
      },
      required = { "pattern", "track" },
    },
    handler = function(args)
      local s  = song()
      local pi = math.floor(tonumber(args.pattern) or -1) + 1
      local ti = math.floor(tonumber(args.track)   or 0)
      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pat = s.patterns[pi]
      if ti < 1 or ti > #pat.tracks then return err("invalid track index") end
      pat.tracks[ti]:clear()
      return text(string.format("Pattern %d, track %d cleared.", pi - 1, ti))
    end,
  },
  {
    name = "pattern_copy",
    description = "Copy all track data and automation from one pattern to another, replacing the destination content.",
    inputSchema = {
      type = "object",
      properties = {
        src  = { type = "number", description = "0-based source pattern index." },
        dest = { type = "number", description = "0-based destination pattern index." },
      },
      required = { "src", "dest" },
    },
    handler = function(args)
      local s  = song()
      local si = math.floor(tonumber(args.src)  or -1) + 1
      local di = math.floor(tonumber(args.dest) or -1) + 1
      if si < 1 or si > #s.patterns then return err("invalid src pattern index") end
      if di < 1 or di > #s.patterns then return err("invalid dest pattern index") end
      if si == di then return err("src and dest must be different") end
      s.patterns[di]:copy_from(s.patterns[si])
      return text(string.format("Pattern %d copied to pattern %d.", si - 1, di - 1))
    end,
  },
  {
    name = "pattern_rename",
    description = "Rename a pattern as shown in the pattern sequencer.",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "0-based pattern index." },
        name  = { type = "string", description = "New pattern name." },
      },
      required = { "index", "name" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or -1) + 1
      if i < 1 or i > #s.patterns then return err("invalid pattern index") end
      s.patterns[i].name = tostring(args.name)
      return text(string.format("Pattern %d renamed to '%s'.", i - 1, args.name))
    end,
  },
  {
    name = "pattern_copy_lines",
    description = [[Copy a contiguous block of lines from one position to another within the same pattern and track. Source and destination ranges must not overlap.
Pattern: 0-based. Track: 1-based. Lines: 1-based.]],
    inputSchema = {
      type = "object",
      properties = {
        pattern   = { type = "number", description = "0-based pattern index." },
        track     = { type = "number", description = "1-based track index." },
        from_line = { type = "number", description = "1-based first source line." },
        count     = { type = "number", description = "Number of lines to copy." },
        to_line   = { type = "number", description = "1-based first destination line." },
      },
      required = { "pattern", "track", "from_line", "count", "to_line" },
    },
    handler = function(args)
      local s  = song()
      local pi = math.floor(tonumber(args.pattern)   or -1) + 1
      local ti = math.floor(tonumber(args.track)     or 0)
      local fl = math.floor(tonumber(args.from_line) or 0)
      local n  = math.floor(tonumber(args.count)     or 0)
      local tl = math.floor(tonumber(args.to_line)   or 0)
      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pat = s.patterns[pi]
      if ti < 1 or ti > #pat.tracks then return err("invalid track index") end
      if n < 1 then return err("count must be >= 1") end
      local nl = pat.number_of_lines
      if fl < 1 or fl + n - 1 > nl then return err("source range out of bounds") end
      if tl < 1 or tl + n - 1 > nl then return err("destination range out of bounds") end
      if not (fl + n - 1 < tl or tl + n - 1 < fl) then
        return err("source and destination ranges overlap")
      end
      local pt        = pat.tracks[ti]
      local src_lines = pt:lines_in_range(fl, fl + n - 1)
      for off, ln in ipairs(src_lines) do
        pt:line(tl + off - 1):copy_from(ln)
      end
      return text(string.format("Copied %d lines from line %d to line %d in pattern %d track %d.",
        n, fl, tl, pi - 1, ti))
    end,
  },
  {
    name = "pattern_move_lines",
    description = [[Move a contiguous block of lines to a new starting position (copy then clear source). Source and destination ranges must not overlap.
Pattern: 0-based. Track: 1-based. Lines: 1-based.]],
    inputSchema = {
      type = "object",
      properties = {
        pattern   = { type = "number", description = "0-based pattern index." },
        track     = { type = "number", description = "1-based track index." },
        from_line = { type = "number", description = "1-based first source line." },
        count     = { type = "number", description = "Number of lines to move." },
        to_line   = { type = "number", description = "1-based first destination line." },
      },
      required = { "pattern", "track", "from_line", "count", "to_line" },
    },
    handler = function(args)
      local s  = song()
      local pi = math.floor(tonumber(args.pattern)   or -1) + 1
      local ti = math.floor(tonumber(args.track)     or 0)
      local fl = math.floor(tonumber(args.from_line) or 0)
      local n  = math.floor(tonumber(args.count)     or 0)
      local tl = math.floor(tonumber(args.to_line)   or 0)
      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pat = s.patterns[pi]
      if ti < 1 or ti > #pat.tracks then return err("invalid track index") end
      if n < 1 then return err("count must be >= 1") end
      local nl = pat.number_of_lines
      if fl < 1 or fl + n - 1 > nl then return err("source range out of bounds") end
      if tl < 1 or tl + n - 1 > nl then return err("destination range out of bounds") end
      if fl == tl then return err("from_line and to_line are the same") end
      if not (fl + n - 1 < tl or tl + n - 1 < fl) then
        return err("source and destination ranges overlap")
      end
      local pt        = pat.tracks[ti]
      local src_lines = pt:lines_in_range(fl, fl + n - 1)
      for off, ln in ipairs(src_lines) do
        pt:line(tl + off - 1):copy_from(ln)
      end
      for li = fl, fl + n - 1 do
        pt:line(li):clear()
      end
      return text(string.format("Moved %d lines from line %d to line %d in pattern %d track %d.",
        n, fl, tl, pi - 1, ti))
    end,
  },
  {
    name = "pattern_set_effect",
    description = [[Set an effect column value in a pattern.
fx: 2-character effect code like "0D", "1B". Pass ".." or "" to clear the column.
Pattern index: 0-based. Track index: 1-based. Line index: 1-based.]],
    inputSchema = {
      type = "object",
      properties = {
        pattern = { type = "number", description = "0-based pattern index." },
        track   = { type = "number", description = "1-based track index." },
        line    = { type = "number", description = "1-based line index." },
        column  = { type = "number", description = "1-based effect column (default 1)." },
        fx      = { type = "string", description = '2-char effect code e.g. "0D". ".." to clear.' },
        amount  = { type = "number", description = "Effect amount 0x00-0xFF (default 0)." },
      },
      required = { "pattern", "track", "line", "fx" },
    },
    handler = function(args)
      local s  = song()
      local pi = math.floor(tonumber(args.pattern) or -1) + 1
      local ti = math.floor(tonumber(args.track)   or 0)
      local li = math.floor(tonumber(args.line)    or 0)
      local ci = math.floor(tonumber(args.column)  or 1)

      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pat = s.patterns[pi]
      if ti < 1 or ti > #pat.tracks then return err("invalid track index") end
      if li < 1 or li > pat.number_of_lines then return err("invalid line index") end

      local song_track = s.tracks[ti]
      while song_track.visible_effect_columns < ci do
        song_track.visible_effect_columns = song_track.visible_effect_columns + 1
      end

      local ec     = pat.tracks[ti]:line(li):effect_column(ci)
      local fx_str = tostring(args.fx or ".."):upper():gsub("%s", "")

      if fx_str == ".." or fx_str == "" then
        ec:clear()
        return text(string.format("Effect column cleared at pattern=%d track=%d line=%d col=%d",
          pi - 1, ti, li, ci))
      end
      if #fx_str ~= 2 then return err("fx must be a 2-character string like '0D'") end

      ec.number_string = fx_str
      ec.amount_value  = math.max(0, math.min(255, math.floor(tonumber(args.amount) or 0)))
      return text(string.format("Set effect %s%02X at pattern=%d track=%d line=%d col=%d",
        fx_str, ec.amount_value, pi - 1, ti, li, ci))
    end,
  },
  {
    name = "pattern_clear",
    description = "Clear all notes and effects in every track of a pattern.",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "0-based pattern index." },
      },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or -1) + 1
      if i < 1 or i > #s.patterns then return err("invalid pattern index") end
      s.patterns[i]:clear()
      return text(string.format("Pattern %d cleared.", i - 1))
    end,
  },
  {
    name = "pattern_fill_random",
    description = [[Fill lines of a track in a pattern with random notes.
note_min / note_max: inclusive note value range (default 36=C-3 to 84=C-7).
instrument_min / instrument_max: random instrument range (0-based); if both omitted uses instrument=0.
step: place a note every N lines (default 1 = every line; 4 = lines 1,5,9,...).
Pattern index: 0-based. Track index: 1-based.]],
    inputSchema = {
      type = "object",
      properties = {
        pattern        = { type = "number", description = "0-based pattern index." },
        track          = { type = "number", description = "1-based track index." },
        note_min       = { type = "number", description = "Min note value 0-119 (default 36 = C-3)." },
        note_max       = { type = "number", description = "Max note value 0-119 (default 84 = C-7)." },
        instrument_min = { type = "number", description = "Min 0-based instrument index (default 0)." },
        instrument_max = { type = "number", description = "Max 0-based instrument index (default same as instrument_min)." },
        step           = { type = "number", description = "Place a note every N lines (default 1)." },
      },
      required = { "pattern", "track" },
    },
    handler = function(args)
      local s  = song()
      local pi = math.floor(tonumber(args.pattern) or -1) + 1
      local ti = math.floor(tonumber(args.track)   or 0)
      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pat = s.patterns[pi]
      if ti < 1 or ti > #pat.tracks then return err("invalid track index") end

      local n_min  = math.max(0, math.min(119, math.floor(tonumber(args.note_min) or 36)))
      local n_max  = math.max(0, math.min(119, math.floor(tonumber(args.note_max) or 84)))
      if n_min > n_max then n_min, n_max = n_max, n_min end

      local i_min  = math.max(0, math.floor(tonumber(args.instrument_min) or 0))
      local i_max  = math.max(0, math.floor(tonumber(args.instrument_max) or i_min))
      if i_min > i_max then i_min, i_max = i_max, i_min end

      local step   = math.max(1, math.floor(tonumber(args.step) or 1))
      local n_rng  = n_max - n_min
      local i_rng  = i_max - i_min

      local pt     = pat.tracks[ti]
      local nl     = pat.number_of_lines
      local filled = 0
      math.randomseed(os.time())
      for li = 1, nl, step do
        local nc = pt:line(li):note_column(1)
        nc.note_value       = n_min + math.random(0, n_rng)
        nc.instrument_value = i_min + math.random(0, i_rng)
        nc.volume_value     = EMPTY_VOLUME
        nc.panning_value    = EMPTY_PANNING
        nc.delay_value      = EMPTY_DELAY
        filled = filled + 1
      end
      return text(string.format(
        "Filled %d lines (step=%d) in pattern %d track %d with random notes (%s-%s), inst=%d-%d.",
        filled, step, pi - 1, ti, note_to_str(n_min), note_to_str(n_max), i_min, i_max))
    end,
  },
  {
    name = "pattern_copy_track",
    description = "Copy all pattern data (notes, effects, automation) from one track to another within the same pattern. Uses Renoise's native copy_from for a full clone including all columns.",
    inputSchema = {
      type = "object",
      properties = {
        pattern    = { type = "number", description = "0-based pattern index." },
        src_track  = { type = "number", description = "1-based source track index." },
        dest_track = { type = "number", description = "1-based destination track index." },
      },
      required = { "pattern", "src_track", "dest_track" },
    },
    handler = function(args)
      local s   = song()
      local pi  = math.floor(tonumber(args.pattern)    or -1) + 1
      local src = math.floor(tonumber(args.src_track)  or 0)
      local dst = math.floor(tonumber(args.dest_track) or 0)

      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pat = s.patterns[pi]
      if src < 1 or src > #pat.tracks then return err("invalid src_track index") end
      if dst < 1 or dst > #pat.tracks then return err("invalid dest_track index") end
      if src == dst then return err("src_track and dest_track must be different") end

      -- Copy column visibility from source song track to dest song track
      local src_t = s.tracks[src]
      local dst_t = s.tracks[dst]
      dst_t.visible_note_columns   = src_t.visible_note_columns
      dst_t.visible_effect_columns = src_t.visible_effect_columns
      dst_t.volume_column_visible         = src_t.volume_column_visible
      dst_t.panning_column_visible        = src_t.panning_column_visible
      dst_t.delay_column_visible          = src_t.delay_column_visible
      dst_t.sample_effects_column_visible = src_t.sample_effects_column_visible

      -- Copy all pattern data (notes + automation)
      pat.tracks[dst]:copy_from(pat.tracks[src])

      return text(string.format(
        "Pattern %d: track %d copied to track %d.", pi - 1, src, dst))
    end,
  },
}
