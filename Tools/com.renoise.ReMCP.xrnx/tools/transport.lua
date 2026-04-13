-- tools/transport.lua
-- Playback transport, BPM, LPB, position controls.

local function text(s)  return { content = {{ type = "text", text = tostring(s) }} } end
local function err(s)   return { content = {{ type = "text", text = tostring(s) }}, isError = true } end

local function song()
  local ok, s = pcall(renoise.song)
  if not ok or not s then error("No song loaded") end
  return s
end

return {
  {
    name = "transport_play",
    description = "Start Renoise playback from the current position.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      song().transport:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)
      return text("Playback started.")
    end,
  },
  {
    name = "transport_continue",
    description = "Continue Renoise playback without restarting the current pattern.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      song().transport:start(renoise.Transport.PLAYMODE_CONTINUE_PATTERN)
      return text("Playback continued.")
    end,
  },
  {
    name = "transport_stop",
    description = "Stop Renoise playback.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      song().transport:stop()
      return text("Playback stopped.")
    end,
  },
  {
    name = "transport_get_position",
    description = "Return current playback position and playing state.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      local t   = song().transport
      local pos = t.playback_pos
      return text(string.format(
        "playing=%s  pattern=%d  line=%d  column=%d",
        tostring(t.playing), pos.pattern, pos.line, pos.column))
    end,
  },
  {
    name = "transport_get_bpm",
    description = "Return the current song BPM.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      return text(string.format("%.2f", song().transport.bpm))
    end,
  },
  {
    name = "transport_set_bpm",
    description = "Set the song BPM (32-999).",
    inputSchema = {
      type = "object",
      properties = {
        bpm = { type = "number", description = "Beats per minute (32-999)." },
      },
      required = { "bpm" },
    },
    handler = function(args)
      local bpm = tonumber(args.bpm)
      if not bpm or bpm < 32 or bpm > 999 then
        return err("bpm must be a number between 32 and 999")
      end
      song().transport.bpm = bpm
      return text(string.format("BPM set to %.2f", bpm))
    end,
  },
  {
    name = "transport_get_lpb",
    description = "Return the current Lines Per Beat (LPB).",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      return text(tostring(song().transport.lpb))
    end,
  },
  {
    name = "transport_panic",
    description = "Stop all currently playing notes (panic).",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      song().transport:panic()
      return text("Panic: all notes stopped.")
    end,
  },
  {
    name = "transport_get_tpl",
    description = "Return the current Ticks Per Line (TPL).",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      return text(tostring(song().transport.tpl))
    end,
  },
  {
    name = "transport_set_tpl",
    description = "Set Ticks Per Line (1-16).",
    inputSchema = {
      type = "object",
      properties = {
        tpl = { type = "number", description = "Ticks per line (1-16)." },
      },
      required = { "tpl" },
    },
    handler = function(args)
      local tpl = math.floor(tonumber(args.tpl) or 0)
      if tpl < 1 or tpl > 16 then return err("tpl must be 1-16") end
      song().transport.tpl = tpl
      return text(string.format("TPL set to %d", tpl))
    end,
  },
  {
    name = "transport_trigger_sequence",
    description = "Immediately start playing at a given 1-based sequence position.",
    inputSchema = {
      type = "object",
      properties = {
        position = { type = "number", description = "1-based sequence row to play from." },
      },
      required = { "position" },
    },
    handler = function(args)
      local s   = song()
      local pos = math.floor(tonumber(args.position) or 0)
      local seq = s.sequencer.pattern_sequence
      if pos < 1 or pos > #seq then return err("sequence position out of range") end
      s.transport:trigger_sequence(pos)
      return text(string.format("Triggered playback at sequence position %d.", pos))
    end,
  },
  {
    name = "transport_set_lpb",
    description = "Set Lines Per Beat (1-255).",
    inputSchema = {
      type = "object",
      properties = {
        lpb = { type = "number", description = "Lines per beat (1-255)." },
      },
      required = { "lpb" },
    },
    handler = function(args)
      local lpb = math.floor(tonumber(args.lpb) or 0)
      if lpb < 1 or lpb > 255 then return err("lpb must be 1-255") end
      song().transport.lpb = lpb
      return text(string.format("LPB set to %d", lpb))
    end,
  },
}
