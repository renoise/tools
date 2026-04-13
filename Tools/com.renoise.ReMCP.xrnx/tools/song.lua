-- tools/song.lua
-- Song-level info and metadata.

local function text(s) return { content = {{ type = "text", text = tostring(s) }} } end
local function err(s)  return { content = {{ type = "text", text = tostring(s) }}, isError = true } end

local function song()
  local ok, s = pcall(renoise.song)
  if not ok or not s then error("No song loaded") end
  return s
end

return {
  {
    name = "song_get_info",
    description = "Return a summary of the current song: name, artist, BPM, LPB, track/pattern/instrument counts.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      local s  = song()
      local tr = s.transport
      local lines = {
        "name:        " .. (s.name   ~= "" and s.name   or "(untitled)"),
        "artist:      " .. (s.artist ~= "" and s.artist or "(unknown)"),
        "bpm:         " .. string.format("%.2f", tr.bpm),
        "lpb:         " .. tostring(tr.lpb),
        "tpl:         " .. tostring(tr.tpl),
        "tracks:      " .. tostring(#s.tracks),
        "patterns:    " .. tostring(#s.patterns),
        "sequence:    " .. tostring(#s.sequencer.pattern_sequence),
        "instruments: " .. tostring(#s.instruments),
      }
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "song_set_name",
    description = "Set the song title.",
    inputSchema = {
      type = "object",
      properties = { name = { type = "string", description = "New song title." } },
      required = { "name" },
    },
    handler = function(args)
      song().name = tostring(args.name or "")
      return text("Song name set to: " .. tostring(args.name))
    end,
  },
  {
    name = "song_undo",
    description = "Undo the last action in the song.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      local s = song()
      if not s:can_undo() then return err("nothing to undo") end
      s:undo()
      return text("Undo performed.")
    end,
  },
  {
    name = "song_redo",
    description = "Redo the last undone action in the song.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      local s = song()
      if not s:can_redo() then return err("nothing to redo") end
      s:redo()
      return text("Redo performed.")
    end,
  },
  {
    name = "song_set_artist",
    description = "Set the song artist.",
    inputSchema = {
      type = "object",
      properties = { artist = { type = "string", description = "Artist name." } },
      required = { "artist" },
    },
    handler = function(args)
      song().artist = tostring(args.artist or "")
      return text("Artist set to: " .. tostring(args.artist))
    end,
  },
}
