-- tools/tracks.lua
-- Track listing, creation, removal, and property editing.

local function text(s) return { content = {{ type = "text", text = tostring(s) }} } end
local function err(s)  return { content = {{ type = "text", text = tostring(s) }}, isError = true } end

local function song()
  local ok, s = pcall(renoise.song)
  if not ok or not s then error("No song loaded") end
  return s
end

local TRACK_TYPE_NAMES = {
  [renoise.Track.TRACK_TYPE_SEQUENCER] = "sequencer",
  [renoise.Track.TRACK_TYPE_MASTER]    = "master",
  [renoise.Track.TRACK_TYPE_SEND]      = "send",
  [renoise.Track.TRACK_TYPE_GROUP]     = "group",
}

local function track_summary(i, track)
  local muted = (track.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE)
  return string.format("[%d] %-24s  type=%-10s  muted=%s  volume=%.2f",
    i,
    track.name ~= "" and track.name or "(unnamed)",
    TRACK_TYPE_NAMES[track.type] or "unknown",
    tostring(muted),
    track.postfx_volume.value)
end

return {
  {
    name = "tracks_list",
    description = "List all tracks with index, name, type, mute state and volume.",
    inputSchema = { type = "object", properties = {}, required = {} },
    handler = function(_)
      local s = song()
      local lines = {}
      for i, t in ipairs(s.tracks) do
        lines[#lines + 1] = track_summary(i, t)
      end
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "track_get_info",
    description = "Return detailed info for a single track by 1-based index.",
    inputSchema = {
      type = "object",
      properties = { index = { type = "number", description = "1-based track index." } },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      local t = s.tracks[i]
      local muted = (t.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE)
      local lines = {
        "index:     " .. tostring(i),
        "name:      " .. t.name,
        "type:      " .. (TRACK_TYPE_NAMES[t.type] or "unknown"),
        "muted:     " .. tostring(muted),
        "solo:      " .. tostring(t.solo_state),
        "volume:    " .. string.format("%.4f", t.postfx_volume.value),
        "color:     " .. string.format("%d %d %d",
          t.color[1], t.color[2], t.color[3]),
        "visible_note_columns: " .. tostring(t.visible_note_columns),
      }
      return text(table.concat(lines, "\n"))
    end,
  },
  {
    name = "track_add",
    description = "Insert a new sequencer track. position is 1-based (default: before master track).",
    inputSchema = {
      type = "object",
      properties = {
        position = { type = "number", description = "1-based insert position." },
        name     = { type = "string", description = "Optional track name." },
      },
      required = {},
    },
    handler = function(args)
      local s   = song()
      -- sequencer_track_count + 1 = position just before master, creating a sequencer track.
      -- Inserting at or after the master track index creates a send track instead.
      local pos = math.floor(tonumber(args.position) or s.sequencer_track_count + 1)
      pos = math.max(1, math.min(pos, s.sequencer_track_count + 1))
      s:insert_track_at(pos)
      if args.name and args.name ~= "" then
        s.tracks[pos].name = tostring(args.name)
      end
      return text(string.format("Track inserted at position %d.", pos))
    end,
  },
  {
    name = "track_remove",
    description = "Remove the track at a 1-based index (must be a sequencer track).",
    inputSchema = {
      type = "object",
      properties = { index = { type = "number", description = "1-based track index." } },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      if s.tracks[i].type ~= renoise.Track.TRACK_TYPE_SEQUENCER and
         s.tracks[i].type ~= renoise.Track.TRACK_TYPE_GROUP then
        return err("can only remove sequencer or group tracks")
      end
      local name = s.tracks[i].name
      s:delete_track_at(i)
      return text(string.format("Track '%s' removed.", name))
    end,
  },
  {
    name = "track_set_name",
    description = "Rename a track.",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "1-based track index." },
        name  = { type = "string", description = "New name." },
      },
      required = { "index", "name" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      s.tracks[i].name = tostring(args.name)
      return text(string.format("Track %d renamed to '%s'.", i, args.name))
    end,
  },
  {
    name = "track_set_volume",
    description = "Set post-FX volume of a track. value is a linear multiplier (0.0 = silent, 1.0 = 0 dB, 3.0 ≈ +9 dB).",
    inputSchema = {
      type = "object",
      properties = {
        index  = { type = "number", description = "1-based track index." },
        volume = { type = "number", description = "Linear volume (0.0-3.0)." },
      },
      required = { "index", "volume" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      local v = tonumber(args.volume)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      if not v or v < 0 then return err("volume must be >= 0") end
      s.tracks[i].postfx_volume.value = v
      return text(string.format("Track %d volume set to %.4f.", i, v))
    end,
  },
  {
    name = "track_set_mute",
    description = "Mute or unmute a track.",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number",  description = "1-based track index." },
        mute  = { type = "boolean", description = "true = mute, false = unmute." },
      },
      required = { "index", "mute" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      s.tracks[i].mute_state = args.mute
        and renoise.Track.MUTE_STATE_MUTED
        or  renoise.Track.MUTE_STATE_ACTIVE
      return text(string.format("Track %d %s.", i, args.mute and "muted" or "unmuted"))
    end,
  },
  {
    name = "track_set_panning",
    description = "Set post-FX panning of a track (0.0 = hard left, 0.5 = centre, 1.0 = hard right).",
    inputSchema = {
      type = "object",
      properties = {
        index   = { type = "number", description = "1-based track index." },
        panning = { type = "number", description = "Panning (0.0-1.0)." },
      },
      required = { "index", "panning" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      local p = tonumber(args.panning)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      if not p or p < 0 or p > 1 then return err("panning must be 0.0-1.0") end
      s.tracks[i].postfx_panning.value = p
      return text(string.format("Track %d panning set to %.4f.", i, p))
    end,
  },
  {
    name = "track_set_solo",
    description = "Solo a track (all other non-send tracks are muted).",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "1-based track index." },
      },
      required = { "index" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      s.tracks[i]:solo()
      return text(string.format("Track %d soloed.", i))
    end,
  },
  {
    name = "track_set_collapsed",
    description = "Collapse or expand a track in the pattern editor.",
    inputSchema = {
      type = "object",
      properties = {
        index     = { type = "number",  description = "1-based track index." },
        collapsed = { type = "boolean", description = "true = collapse, false = expand." },
      },
      required = { "index", "collapsed" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      s.tracks[i].collapsed = args.collapsed and true or false
      return text(string.format("Track %d %s.", i, args.collapsed and "collapsed" or "expanded"))
    end,
  },
  {
    name = "track_move",
    description = "Move a track to a new 1-based position using sequential swaps. Source and all intermediate tracks must be the same type (regular, send, etc.).",
    inputSchema = {
      type = "object",
      properties = {
        from = { type = "number", description = "1-based current track index." },
        to   = { type = "number", description = "1-based target position." },
      },
      required = { "from", "to" },
    },
    handler = function(args)
      local s    = song()
      local from = math.floor(tonumber(args.from) or 0)
      local to   = math.floor(tonumber(args.to)   or 0)
      if from < 1 or from > #s.tracks then return err("invalid 'from' index") end
      if to   < 1 or to   > #s.tracks then return err("invalid 'to' index") end
      if from == to then return text("Track already at target position.") end
      local step = from < to and 1 or -1
      for i = from, to - step, step do
        s:swap_tracks_at(i, i + step)
      end
      return text(string.format("Track moved from position %d to %d.", from, to))
    end,
  },
  {
    name = "track_swap",
    description = "Swap the positions of two tracks. Both must be the same type (regular↔regular or send↔send).",
    inputSchema = {
      type = "object",
      properties = {
        index1 = { type = "number", description = "1-based index of the first track." },
        index2 = { type = "number", description = "1-based index of the second track." },
      },
      required = { "index1", "index2" },
    },
    handler = function(args)
      local s  = song()
      local i1 = math.floor(tonumber(args.index1) or 0)
      local i2 = math.floor(tonumber(args.index2) or 0)
      if i1 < 1 or i1 > #s.tracks then return err("invalid index1") end
      if i2 < 1 or i2 > #s.tracks then return err("invalid index2") end
      if i1 == i2 then return err("index1 and index2 must be different") end
      s:swap_tracks_at(i1, i2)
      return text(string.format("Tracks %d and %d swapped.", i1, i2))
    end,
  },
  {
    name = "track_set_color",
    description = "Set the track color using R G B values (0-255 each).",
    inputSchema = {
      type = "object",
      properties = {
        index = { type = "number", description = "1-based track index." },
        r     = { type = "number", description = "Red   (0-255)." },
        g     = { type = "number", description = "Green (0-255)." },
        b     = { type = "number", description = "Blue  (0-255)." },
      },
      required = { "index", "r", "g", "b" },
    },
    handler = function(args)
      local s = song()
      local i = math.floor(tonumber(args.index) or 0)
      if i < 1 or i > #s.tracks then return err("invalid track index") end
      local r = math.max(0, math.min(255, math.floor(tonumber(args.r) or 0)))
      local g = math.max(0, math.min(255, math.floor(tonumber(args.g) or 0)))
      local b = math.max(0, math.min(255, math.floor(tonumber(args.b) or 0)))
      s.tracks[i].color = { r, g, b }
      return text(string.format("Track %d color set to rgb(%d,%d,%d).", i, r, g, b))
    end,
  },
  {
    name = "track_group_add",
    description = "Insert a new empty group track at the given 1-based position (must be before the Master track).",
    inputSchema = {
      type = "object",
      properties = {
        position = { type = "number", description = "1-based insert position (default: end of sequencer tracks)." },
        name     = { type = "string", description = "Optional group track name." },
      },
      required = {},
    },
    handler = function(args)
      local s   = song()
      local pos = math.floor(tonumber(args.position) or s.sequencer_track_count + 1)
      pos = math.max(1, math.min(pos, s.sequencer_track_count + 1))
      local grp = s:insert_group_at(pos)
      if args.name and args.name ~= "" then
        grp.name = tostring(args.name)
      end
      return text(string.format("Group track inserted at position %d.", pos))
    end,
  },
  {
    name = "track_group_add_member",
    description = "Add a track into a group track. If the target index is not already a group, a new group is created containing both tracks.",
    inputSchema = {
      type = "object",
      properties = {
        track_index = { type = "number", description = "1-based index of the track to add to the group." },
        group_index = { type = "number", description = "1-based index of the group (or any track to form a new group)." },
      },
      required = { "track_index", "group_index" },
    },
    handler = function(args)
      local s  = song()
      local ti = math.floor(tonumber(args.track_index) or 0)
      local gi = math.floor(tonumber(args.group_index) or 0)
      if ti < 1 or ti > #s.tracks then return err("invalid track_index") end
      if gi < 1 or gi > #s.tracks then return err("invalid group_index") end
      if ti == gi then return err("track_index and group_index must be different") end
      s:add_track_to_group(ti, gi)
      return text(string.format("Track %d added to group at index %d.", ti, gi))
    end,
  },
  {
    name = "track_group_remove_member",
    description = "Remove a track from its parent group and place it to the left of the group.",
    inputSchema = {
      type = "object",
      properties = {
        track_index = { type = "number", description = "1-based index of the grouped track to remove." },
      },
      required = { "track_index" },
    },
    handler = function(args)
      local s  = song()
      local ti = math.floor(tonumber(args.track_index) or 0)
      if ti < 1 or ti > #s.tracks then return err("invalid track_index") end
      if not s.tracks[ti].group_parent  then return err("track is not part of a group") end
      s:remove_track_from_group(ti)
      return text(string.format("Track %d removed from its group.", ti))
    end,
  },
}
