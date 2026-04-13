-- tools/sequencer.lua
-- Song sequence (arrangement) management.
-- The sequencer maps pattern indices to playback order.
-- Sequence positions are 1-based here (matching Renoise UI rows).

local function text(s) return { content = {{ type = "text", text = tostring(s) }} } end
local function err(s)  return { content = {{ type = "text", text = tostring(s) }}, isError = true } end

local function song()
  local ok, s = pcall(renoise.song)
  if not ok or not s then error("No song loaded") end
  return s
end

return {
  {
    name = "sequencer_list",
    description = "Return the full song sequence — each row shows the sequence position and the pattern index it plays.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      local s   = song()
      local seq = s.sequencer.pattern_sequence
      local lines = {}
      for i, pat_idx in ipairs(seq) do
        lines[#lines + 1] = string.format("seq[%03d] -> pattern %02d", i, pat_idx - 1)
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "sequencer_insert",
    description = "Insert a pattern into the song sequence at a given position. Sequence position is 1-based.",
    inputSchema = {
      type = "object",
      properties = {
        position      = { type = "number", description = "1-based sequence row to insert before (default: append at end)." },
        pattern_index = { type = "number", description = "0-based pattern index to insert." },
      },
      required = { "pattern_index" },
    },
    handler = function(args)
      local s        = song()
      local seq      = s.sequencer.pattern_sequence
      local pi       = math.floor(tonumber(args.pattern_index) or -1) + 1
      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      local pos = math.floor(tonumber(args.position) or #seq + 1)
      pos = math.max(1, math.min(pos, #seq + 1))
      s.sequencer:insert_sequence_at(pos, pi)
      return text(string.format("Pattern %d inserted at sequence position %d.", pi - 1, pos))
    end,
  },
  {
    name = "sequencer_remove",
    description = "Remove a row from the song sequence by 1-based position.",
    inputSchema = {
      type = "object",
      properties = {
        position = { type = "number", description = "1-based sequence row to remove." },
      },
      required = { "position" },
    },
    handler = function(args)
      local s   = song()
      local pos = math.floor(tonumber(args.position) or 0)
      local seq = s.sequencer.pattern_sequence
      if pos < 1 or pos > #seq then return err("sequence position out of range") end
      s.sequencer:delete_sequence_at(pos)
      return text(string.format("Sequence row %d removed.", pos))
    end,
  },
  {
    name = "sequencer_set_pattern",
    description = "Change which pattern plays at a given sequence position.",
    inputSchema = {
      type = "object",
      properties = {
        position      = { type = "number", description = "1-based sequence row." },
        pattern_index = { type = "number", description = "0-based pattern index." },
      },
      required = { "position", "pattern_index" },
    },
    handler = function(args)
      local s   = song()
      local pos = math.floor(tonumber(args.position) or 0)
      local pi  = math.floor(tonumber(args.pattern_index) or -1) + 1
      local seq = s.sequencer.pattern_sequence
      if pos < 1 or pos > #seq then return err("sequence position out of range") end
      if pi < 1 or pi > #s.patterns then return err("invalid pattern index") end
      s.sequencer:set_pattern(pos, pi)
      return text(string.format("Sequence row %d now plays pattern %d.", pos, pi - 1))
    end,
  },
  {
    name = "sequencer_new_pattern",
    description = "Create a new empty pattern and insert it into the sequence at the given 1-based position. Returns the new 0-based pattern index.",
    inputSchema = {
      type = "object",
      properties = {
        position = { type = "number", description = "1-based sequence row to insert at (default: append at end)." },
      },
      required = {},
    },
    handler = function(args)
      local s   = song()
      local seq = s.sequencer.pattern_sequence
      local pos = math.floor(tonumber(args.position) or #seq + 1)
      pos = math.max(1, math.min(pos, #seq + 1))
      local new_pi = s.sequencer:insert_new_pattern_at(pos)
      return text(string.format("New pattern %d created at sequence position %d.", new_pi - 1, pos))
    end,
  },
  {
    name = "sequencer_move",
    description = "Move a sequence slot from one 1-based position to another, preserving all other slots' relative order.",
    inputSchema = {
      type = "object",
      properties = {
        from = { type = "number", description = "1-based current sequence row to move." },
        to   = { type = "number", description = "1-based target sequence row." },
      },
      required = { "from", "to" },
    },
    handler = function(args)
      local s    = song()
      local seq  = s.sequencer.pattern_sequence
      local from = math.floor(tonumber(args.from) or 0)
      local to   = math.floor(tonumber(args.to)   or 0)
      if from < 1 or from > #seq then return err("'from' out of range") end
      if to   < 1 or to   > #seq then return err("'to' out of range") end
      if from == to then return text("Sequence slot already at target position.") end
      local pi = s.sequencer:pattern(from)  -- 1-based pattern index at source slot
      s.sequencer:delete_sequence_at(from)
      s.sequencer:insert_sequence_at(to, pi)
      return text(string.format("Sequence slot moved from position %d to %d.", from, to))
    end,
  },
  {
    name = "sequencer_clone_range",
    description = "Clone a contiguous range of sequence slots and append the copy immediately after the range.",
    inputSchema = {
      type = "object",
      properties = {
        from = { type = "number", description = "1-based start of the range to clone." },
        to   = { type = "number", description = "1-based end of the range to clone." },
      },
      required = { "from", "to" },
    },
    handler = function(args)
      local s    = song()
      local seq  = s.sequencer.pattern_sequence
      local from = math.floor(tonumber(args.from) or 0)
      local to   = math.floor(tonumber(args.to)   or 0)
      if from < 1 or from > #seq         then return err("'from' out of range") end
      if to < from or to > #seq          then return err("'to' must be >= 'from' and within range") end
      s.sequencer:clone_range(from, to)
      return text(string.format("Sequence rows %d-%d cloned (appended after row %d).", from, to, to))
    end,
  },
  {
    name = "sequencer_jump_to",
    description = "Jump playback to a specific sequence position.",
    inputSchema = {
      type = "object",
      properties = {
        position = { type = "number", description = "1-based sequence row." },
      },
      required = { "position" },
    },
    handler = function(args)
      local s   = song()
      local pos = math.floor(tonumber(args.position) or 0)
      local seq = s.sequencer.pattern_sequence
      if pos < 1 or pos > #seq then return err("sequence position out of range") end
      -- Adjust the playback position
      local new_pos        = renoise.SongPos()
      new_pos.sequence     = pos
      new_pos.line         = 1
      s.transport.playback_pos = new_pos
      return text(string.format("Jumped to sequence position %d.", pos))
    end,
  },
}
