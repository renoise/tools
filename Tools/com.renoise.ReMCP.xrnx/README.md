# Renoise MCP

**ReMCP** is a [Model Context Protocol](https://modelcontextprotocol.io/) server that runs inside Renoise and exposes the full song API to any MCP-compatible AI client (Claude Desktop, Claude Code, etc.). You can ask an AI assistant to compose, arrange, mix, and edit your song using natural language.

---

## Installation

1. Copy (or symlink) the `com.renoise.ReMCP.xrnx` folder into your Renoise Tools directory:
   - **macOS:** `~/Library/Preferences/Renoise/V3.x.x/Scripts/Tools/`
   - **Windows:** `%APPDATA%\Renoise\V3.x.x\Scripts\Tools\`
   - **Linux:** `~/.renoise/V3.x.x/Scripts/Tools/`
2. Start Renoise. The tool loads automatically.
3. Open the control panel via **Main Menu → Tools → Renoise MCP…** and click **Start Server**.

---

## Connecting an AI client

### Claude Desktop (recommended)

Add this to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "renoise": {
      "type": "streamable-http",
      "url": "http://localhost:19714/mcp"
    }
  }
}
```

### Claude Code / any MCP client via mcp-remote

```bash
npx -y mcp-remote http://localhost:19714/mcp
```

### Default port

`19714` — changeable in the ReMCP control panel dialog.

---

## Index conventions

| Object | In Renoise UI | In MCP tools |
|---|---|---|
| Patterns | 0-based | 0-based |
| Instruments | 0-based | 0-based |
| Tracks | 1-based | 1-based |
| Lines | 1-based | 1-based |
| Note columns | 1-based | 1-based |
| Effect columns | 1-based | 1-based |
| DSP devices | 1-based | 1-based (index 1 = Mixer, non-removable) |

---

## Tool reference

### Song

| Tool | Description |
|---|---|
| `song_get_info` | Return song name, artist, BPM, LPB, TPL, track/pattern/instrument counts |
| `song_set_name` | Set the song title |
| `song_set_artist` | Set the artist name |
| `song_undo` | Undo the last action |
| `song_redo` | Redo the last undone action |

---

### Transport

| Tool | Description |
|---|---|
| `transport_play` | Start playback from the current position |
| `transport_continue` | Continue playback without restarting the pattern |
| `transport_stop` | Stop playback |
| `transport_panic` | Stop all playing notes |
| `transport_get_position` | Return current sequence/line position and playing state |
| `transport_get_bpm` | Return current BPM |
| `transport_set_bpm` | Set BPM (32–999) |
| `transport_get_lpb` | Return current Lines Per Beat |
| `transport_set_lpb` | Set Lines Per Beat (1–255) |
| `transport_get_tpl` | Return current Ticks Per Line |
| `transport_set_tpl` | Set Ticks Per Line (1–16) |
| `transport_trigger_sequence` | Immediately start playing at a given 1-based sequence position |

---

### Tracks

| Tool | Description |
|---|---|
| `tracks_list` | List all tracks with index, name, type, mute state, volume |
| `track_get_info` | Detailed info for one track (name, type, mute, solo, volume, color, columns) |
| `track_add` | Insert a new sequencer track at a 1-based position |
| `track_remove` | Remove a sequencer or group track |
| `track_set_name` | Rename a track |
| `track_set_volume` | Set post-FX volume (0.0 silent → 1.0 = 0 dB → 3.0 ≈ +9 dB) |
| `track_set_panning` | Set post-FX panning (0.0 = left, 0.5 = centre, 1.0 = right) |
| `track_set_mute` | Mute or unmute a track |
| `track_set_solo` | Solo a track |
| `track_set_collapsed` | Collapse or expand a track in the pattern editor |
| `track_set_color` | Set track color (R, G, B, 0–255 each) |
| `track_move` | Move a track to a new position using sequential swaps |
| `track_swap` | Swap two tracks of the same type |
| `track_group_add` | Insert a new empty group track |
| `track_group_add_member` | Add a track to a group |
| `track_group_remove_member` | Remove a track from its group |

---

### Patterns

| Tool | Description |
|---|---|
| `patterns_list` | List all patterns with their 0-based index and line count |
| `pattern_get_info` | Return line count and track count for one pattern |
| `pattern_set_length` | Set pattern length in lines (1–512) |
| `pattern_rename` | Rename a pattern |
| `pattern_clear` | Clear all tracks in a pattern |
| `pattern_clear_track` | Clear all data in one track of a pattern |
| `pattern_copy` | Copy an entire pattern to another pattern slot |
| `pattern_get_notes` | Read all non-empty note and effect columns in a pattern track. Each note column reports note, instrument, volume, panning, delay, and per-column effects. |
| `pattern_set_note` | Write a single note (with optional instrument, volume, panning, delay) |
| `pattern_set_effect` | Write an effect column value (e.g. `0D`, `1B`) with amount |
| `pattern_copy_track` | Copy all data from one track to another within the same pattern using Renoise's native `copy_from`, preserving all columns and automation |
| `pattern_copy_lines` | Copy a contiguous block of lines to a new position within the same pattern track |
| `pattern_move_lines` | Move a block of lines (copy then clear source) |

---

### Sequencer (Song Arrangement)

| Tool | Description |
|---|---|
| `sequencer_list` | Show the full sequence — each row maps a position to a pattern index |
| `sequencer_insert` | Insert a pattern at a given 1-based sequence position |
| `sequencer_remove` | Remove a sequence row |
| `sequencer_set_pattern` | Change which pattern plays at a given sequence row |
| `sequencer_new_pattern` | Create a new empty pattern and insert it into the sequence |
| `sequencer_move` | Move a sequence slot to a new position |
| `sequencer_clone_range` | Clone a range of sequence rows and append the copy after the range |
| `sequencer_jump_to` | Jump playback position to a sequence row |

---

### Instruments

| Tool | Description |
|---|---|
| `instruments_list` | List all instruments with index, name, sample count, and plugin info |
| `instrument_get_info` | Detailed info for one instrument including sample list |
| `instrument_set_name` | Rename an instrument |
| `instrument_add` | Add a new blank instrument |
| `instrument_remove` | Remove an instrument (must keep at least one) |
| `instrument_set_volume` | Set global instrument volume (linear, 1.0 = 0 dB) |
| `instrument_set_transpose` | Set global transpose in semitones (−120 to +120) |
| `sample_list` | List all samples in an instrument with volume, panning, frame count |
| `sample_set_name` | Rename a sample |
| `sample_add` | Add a new empty sample slot |
| `sample_remove` | Remove a sample slot |

---

### DSP Devices (FX Chains)

| Tool | Description |
|---|---|
| `track_devices_list` | List all devices in a track's FX chain |
| `track_devices_available` | List device paths that can be inserted on a track, with optional text filter |
| `track_device_add` | Insert a device by path at a given chain position |
| `track_device_remove` | Remove a device (index ≥ 2; index 1 is the non-removable Mixer) |
| `track_device_move` | Swap two devices within a chain |
| `track_device_set_active` | Enable or bypass a device |
| `track_device_get_params` | List all parameters of a device with current values and ranges |
| `track_device_set_param` | Set a device parameter value by index |

---

## Adding custom tools

Drop a new `.lua` file into the `tools/` folder. Each file must return a table of tool definitions:

```lua
return {
  {
    name = "my_tool",
    description = "What this tool does",
    inputSchema = {
      type = "object",
      properties = {
        value = { type = "number", description = "An input number." },
      },
      required = { "value" },
    },
    handler = function(args)
      local result = args.value * 2
      return { content = {{ type = "text", text = tostring(result) }} }
    end,
  },
}
```

Reload the tool in Renoise (**Help → Reload All Tools**) to pick up changes. The router auto-discovers all files in `tools/`.

---

## Architecture

```
main.lua            — entry point, menu entries, keybinding
mcp/
  server.lua        — HTTP/TCP server via renoise.Socket (port 19714)
  router.lua        — MCP JSON-RPC dispatcher; auto-loads tools/*.lua
  json.lua          — pure Lua JSON encoder/decoder
tools/
  song.lua          — song info and metadata
  transport.lua     — playback, BPM, LPB, TPL
  tracks.lua        — track management
  patterns.lua      — pattern editing (notes, effects, copy, move)
  sequencer.lua     — song arrangement
  instruments.lua   — instruments and samples
  devices.lua       — DSP FX chain management
ui/
  dialog.lua        — control panel (start/stop server, log, setup info)
```

**Transport:** Streamable HTTP — single `POST /mcp` endpoint returns `application/json`.

---

## Requirements

- Renoise 3.4 or later (Lua API version 6)
- A running Renoise instance with a song loaded
- An MCP-compatible client (Claude Desktop, Claude Code, or any client supporting Streamable HTTP)
