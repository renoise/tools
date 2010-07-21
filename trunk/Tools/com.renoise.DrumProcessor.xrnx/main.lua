-- ============================================================

--  consts

local TOOL_NAME = "Drum Processor"
local TOOL_VERSION = "0.1"
local TOOL_AUTHOR = "kRAkEn/gORe"

local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

local BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
local BUTTON_WIDTH = 86
local SEQUENCER_BUTTON_SIZE = 38
local HELP_BUTTON_WIDTH = 10

local POPUP_WIDTH = 2*BUTTON_WIDTH - 2*DEFAULT_MARGIN

local NOTE_WIDTH = 40
local NUMBER_WIDTH = 30
local DEFAULT_CELL_WIDTH = 196
local TEXT_ROW_WIDTH = 76

local OFF_COLOR = { 0, 0, 0 }


--  locals

local maindialog = nil


-- functions

local function show_status(message)
  renoise.app():show_status(message); print(message)
end

local function clamp(value, min, max)
  return math.max(min, math.min(max, value))
end

local function note_number_to_string(num)
  local note_names = {
    "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B" }
  local note = num % 12
  local octave = (num - note) / 12
  return note_names[note + 1] .. octave
end

local function note_string_to_number(str)
  local note_names = {
    "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B" }
  local octave = 0 + string.sub(str, 3, 3)
  local note = table.find(note_names, string.sub(str, 1, 2))
  if note ~= nil then
    return octave * 12 + (note - 1)
  else
    return -1
  end
end


-- ============================================================

-- menu entries

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Drum Processor...",
  invoke = function() 
    if not maindialog or not maindialog.visible then
        show_dialog()
    end
  end
}


-- ============================================================

class 'DrumPatternProcessor'

--------------------------------------------------------------
function DrumPatternProcessor:__init()
  self.effects = {}
  self.sequencer = {}

  self.pattern_index = 1
  self.use_selected_pattern = true

  self.track_index = 1
  self.use_selected_track = true

  self.instrument_index = 0
  self.use_selected_instrument = true

  self.base_note = "C-4"
  self.preserve_notes = false

  self.play_pos = 0
  self.selected_fx = 1

  self:set_divisions(16)
end

--------------------------------------------------------------
function DrumPatternProcessor:add_effect(effect)
  effect:set_processor(self)
  table.insert(self.effects, effect)
end

--------------------------------------------------------------
function DrumPatternProcessor:get_effect(index)
  return self.effects[index]
end

--------------------------------------------------------------
function DrumPatternProcessor:get_effects(name)
  return self.effects
end

--------------------------------------------------------------
function DrumPatternProcessor:get_effects_name()
  local names = {}
  for k,v in pairs(self.effects) do
    table.insert(names, v.name)
  end
  return names
end

--------------------------------------------------------------
function DrumPatternProcessor:set_track_index(track_index)
  if (track_index >= 0 and track_index < #renoise.song().tracks) then
    local track = renoise.song().tracks[track_index]
    if track.type ~= renoise.Track.TRACK_TYPE_MASTER and
       track.type ~= renoise.Track.TRACK_TYPE_SEND then
      self.track_index = track_index
    else
      renoise.app():show_warning("Cannot select Master or Send-tracks!")     
    end
  end
end

--------------------------------------------------------------
function DrumPatternProcessor:set_divisions(divisions)
  if (divisions >= 1 and divisions <= 16) then
    self.divisions = divisions
    self:on_update_sequencer()
  else
    renoise.app():show_warning("Cannot select " .. divisions .. " divisions!")     
  end
end

--------------------------------------------------------------
function DrumPatternProcessor:clear(pattern, track)
  renoise.song().patterns[pattern].tracks[track]:clear()
end

--------------------------------------------------------------
function DrumPatternProcessor:process()

  local song = renoise.song()
  
  -- choose the pattern
  local pattern = self.pattern_index
  if self.use_selected_pattern then
    pattern = song.selected_pattern_index
  end
  
  -- choose the track
  local track = self.track_index
  if self.use_selected_track then
    track = song.selected_track_index
  end

  -- choose the instrument  
  local instrument = self.instrument_index
  if self.use_selected_instrument then
    instrument = song.selected_instrument_index
  end
  
  -- choose options
  local basenote = self.base_note
  local length = self.effect_length

  -- running values    
  local pos = 0
  local lines = song.patterns[pattern].number_of_lines

  local max_length = lines / self.divisions
  local max_ilength = math.floor(max_length + 0.5)

  local fx = nil
  local currentfx = 0
  local currentfxindex = 0

  -- reset sequencer position
  self.play_pos = 0

  -- TODO: don't do it, let the effect handle this in order to allow "preserve_notes"
  self:clear(pattern, track)
  
  --[[
  -- update visible columns
  if song.tracks[track].visible_effect_columns ~= #self.effects then
    song.tracks[track].visible_effect_columns = #self.effects
  end
  ]]--
  
  -- iterate over lines in current track
  local iter = song.pattern_iterator:lines_in_pattern_track(pattern, track)
  for _,line in iter do

    -- determine a new sequencer play position
    if pos % max_ilength == 0 then
      self.play_pos = self.play_pos + 1
      currentfxindex = 0
    end

    -- which is our current fx
    currentfx = self.sequencer[self.play_pos]
    fx = self.effects[currentfx]
    
    -- we should process an effect or silence
    if fx ~= nil then
      fx:on_process(pattern,
                    track,
                    instrument - 1,
                    (pos - currentfxindex) + 1,
                    max_ilength,
                    currentfxindex)
                    
      currentfxindex = currentfxindex + 1
    else
      -- TODO: clear the line as we are in no fx mode
    end
  
    pos = pos + 1
  end
end

--------------------------------------------------------------
function DrumPatternProcessor:on_update_sequencer()
  if #self.sequencer < self.divisions then
    local new_table_size = (self.divisions - #self.sequencer)
    for numstep = 1,new_table_size do
      table.insert(self.sequencer, 0)
    end
  end
end

--------------------------------------------------------------
function DrumPatternProcessor:build_effect_racks(builder)
  -- main view is a column
  local main_column = builder:column {  
    spacing = DEFAULT_SPACING,
  }

  -- the add a new row with up to 3 modules each
  local effect_row
  for i = 1,#self.effects do
    if (not effect_row or ((i - 1) % 3) == 0) then
      effect_row = builder:row {
        uniform = true,
        spacing = DEFAULT_SPACING
      }
      main_column:add_child(effect_row)
    end
    effect_row:add_child(
      self.effects[i]:on_build_view(builder)
    )
  end

  -- put the sequencer below
  main_column:add_child(
    builder:space{ height = DEFAULT_SPACING }
  )

  return main_column
end

--------------------------------------------------------------
function DrumPatternProcessor:build_sequencer(builder)
  local seq_row = builder:row {
    style = "group",
    margin = DEFAULT_MARGIN
  }
  for numstep = 1,self.divisions do
    seq_row:add_child(
      builder:button {
        text = "",
        id = "__SEQ__" .. numstep,
        width = SEQUENCER_BUTTON_SIZE,
        height = SEQUENCER_BUTTON_SIZE,
        color = OFF_COLOR,
        notifier = function ()
          local button = builder.views["__SEQ__" .. numstep]
          if self.selected_fx == 0 or self.sequencer[numstep] == self.selected_fx then
            button.color = OFF_COLOR
            self.sequencer[numstep] = 0
          else
            button.color = self.effects[self.selected_fx].color
            self.sequencer[numstep] = self.selected_fx
          end
        end
      }
    )
  end
  return seq_row
end

--------------------------------------------------------------
function DrumPatternProcessor:build_options(builder)
  local main_column = builder:column {  
    style = "group",
    spacing = DEFAULT_SPACING,
    margin = DEFAULT_MARGIN,
    uniform = true,

    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Base note"
      },
      builder:valuebox {
        --width = BUTTON_WIDTH,
        min = 0,
        max = 119,
        value = note_string_to_number(self.base_note),
        tostring = function(num)
          return note_number_to_string(num)
        end,
        tonumber = function(str)
          return note_string_to_number(str)
        end,
        notifier = function(value)
          self.base_note = note_number_to_string(value)
        end,
      }
    },

    --[[
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Instrument"
      },
      builder:valuebox {
        --width = BUTTON_WIDTH,
        min = 0,
        max = 255,
        value = note_string_to_number(self.base_note),
        tostring = function(num)
          return note_number_to_string(num)
        end,
        tonumber = function(str)
          return note_string_to_number(str)
        end,
        notifier = function(value)
          self.base_note = note_number_to_string(value)
        end,
      }
    }
    ]]--
  }
  return main_column
end


-- ============================================================

class 'DrumPatternEffect'

--------------------------------------------------------------
function DrumPatternEffect:__init(name, column, color)
  self.name = name
  self.column = column
  self.processor = nil
  self.color = color
end

--------------------------------------------------------------
function DrumPatternEffect:set_processor(processor)
  self.processor = processor
end

--------------------------------------------------------------
function DrumPatternEffect:get_processor()
  return self.processor
end

--------------------------------------------------------------
function DrumPatternEffect:reset_notes_for_line(line)
  if not self.processor.preserve_notes then
    for _,col in pairs(line.note_columns) do
      col.note_string = "---"
      col.volume_string = ".."
      col.instrument_string = ".."  
    end
  end
end

--------------------------------------------------------------
function DrumPatternEffect:reset_effects_for_line(line)
  for _,col in pairs(line.effect_columns) do
    col.number_string = ".."
    col.amount_string = ".."  
  end
end

--------------------------------------------------------------
function DrumPatternEffect:reset_effect_in_column(line, col)
  line.effect_columns[col].number_string = ".."
  line.effect_columns[col].amount_string = ".."  
end

--------------------------------------------------------------
function DrumPatternEffect:build_default_controls(builder)
  local default_color = OFF_COLOR
  local default_text = ""
  
  if self.processor.selected_fx == self.column then
    default_color = self.color
    default_text = ""
  end
  
  return builder:column {
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text { width = TEXT_ROW_WIDTH, text = self.name, font = "bold", align = "left" },
      builder:button {
        width = DEFAULT_CELL_WIDTH - TEXT_ROW_WIDTH,
        id = "__FXBUTTON__" .. self.column,
        text = default_text,
        color = default_color,
        notifier = function()
          for view = 1,#self.processor.effects do
            local button_name = "__FXBUTTON__" .. view
            builder.views[button_name].color = OFF_COLOR
            builder.views[button_name].text = ""
          end
          if self.processor.selected_fx == self.column then
            self.processor.selected_fx = 0
          else
            local button_name = "__FXBUTTON__" .. self.column
            builder.views[button_name].color = self.color
            builder.views[button_name].text = ""
            self.processor.selected_fx = self.column
          end
        end
      }
    },
    builder:space { height = 3 * DEFAULT_SPACING }
  }
end

--------------------------------------------------------------
function DrumPatternEffect:build_parameter_row(builder, name, control)
  return builder:row {
    width = DEFAULT_CELL_WIDTH,
    builder:text {
      width = TEXT_ROW_WIDTH,
      text = name
    },
    control
  }
end

--------------------------------------------------------------
function DrumPatternEffect:on_build_view(builder)
  assert(false) -- cannot use this directly !
end

--------------------------------------------------------------
function DrumPatternEffect:on_process(pattern,
                                      track,
                                      instrument,
                                      start_line,
                                      num_lines,
                                      line_index)
  assert(false) -- cannot use this directly !
end


-- ============================================================

class 'DrumPatternSlicer' (DrumPatternEffect)

--------------------------------------------------------------
function DrumPatternSlicer:__init()
  DrumPatternEffect.__init(self, "Slice", 1, { 255, 0, 0 })
  self.random = false
  self.offset = 0
  self.compression = 0.0
  self.beat_reset = 8
  self.quantize = true
end

--------------------------------------------------------------
function DrumPatternSlicer:on_process(pattern,
                                      track,
                                      instrument,
                                      start_line,
                                      num_lines,
                                      line_index)

  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]
  local processor = self:get_processor()

  self:reset_notes_for_line(line)
  self:reset_effect_in_column(line, 1)
  
  if line_index == 0 then
    if not processor.preserve_notes then
      line.note_columns[1].note_string = processor.base_note
      line.note_columns[1].volume_string = ".."
      line.note_columns[1].instrument_value = instrument
    end
    if line.note_columns[1].note_string ~= "---" then
      line.effect_columns[1].number_value = 0x09

      local line_offset = start_line / num_lines % self.beat_reset
      local slice = line_offset

      if self.quantize then
        slice = ((math.floor(slice * (1.0 + self.compression * 2.0)) % 16) + self.offset) * 16
      else
        slice = (math.floor(slice * (1.0 + self.compression * 15.0)) % 255) + self.offset
      end

      line.effect_columns[1].amount_value = clamp(slice, 0, 255)
    end
  end
end

--------------------------------------------------------------
function DrumPatternSlicer:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    
    self:build_default_controls(builder),

    self:build_parameter_row(builder,
      "Offset", builder:valuebox {
        --width = BUTTON_WIDTH,
        min = 0,
        max = 15,
        value = self.offset,
        notifier = function(value)
          self.offset = value
        end
      }
    ),

    self:build_parameter_row(builder,
      "Reset Beat", builder:valuebox {
        --width = BUTTON_WIDTH,
        min = 1,
        max = 16,
        value = self.beat_reset,
        notifier = function(value)
          self.beat_reset = value
        end
      }
    ),
    
    self:build_parameter_row(builder,
      "Compression", builder:slider {
        --width = DEFAULT_CELL_WIDTH - TEXT_ROW_WIDTH,
        min = 0.0,
        max = 1.0,
        value = self.compression,
        notifier = function(value)
          self.compression = value
        end
      }
    ),

    self:build_parameter_row(builder,
      "Quantize", builder:checkbox {
        value = self.quantize,
        notifier = function(value)
          self.quantize = value
        end
      }
    )
  }
end


-- ============================================================

class 'DrumPatternRepeater' (DrumPatternEffect)

--------------------------------------------------------------
function DrumPatternRepeater:__init()
  DrumPatternEffect.__init(self, "Repeat", 2, { 0, 255, 0 })
  self.random = false
  self.time = 0
  self.repeats = 4
end

--------------------------------------------------------------
function DrumPatternRepeater:on_process(pattern,
                                        track,
                                        instrument,
                                        start_line,
                                        num_lines,
                                        line_index)
 
  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]
  local processor = self:get_processor()
  
  if not processor.preserve_notes then
    self:reset_notes_for_line(line)
    self:reset_effect_in_column(line, 1)
    
    line.note_columns[1].note_string = processor.base_note
    line.note_columns[1].volume_string = ".."
    line.note_columns[1].instrument_value = instrument
  end
  if line.note_columns[1].note_string ~= "---" then
    local repeats = self.repeats
    local time = self.time

    if self.random then
      time = math.random(0, 15)
      repeats = math.random(0, 15)
    end
    
    time = string.format("%x", time)
    repeats = string.format("%x", repeats)
    
    line.effect_columns[1].number_string = "0E"
    line.effect_columns[1].amount_string = time .. repeats
  end
end

--------------------------------------------------------------
function DrumPatternRepeater:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,

    self:build_default_controls(builder),

    self:build_parameter_row(builder,
      "Random", builder:checkbox {
        value = self.random,
        notifier = function(value)
          self.random = value
        end
      }
    ),
    
    self:build_parameter_row(builder,
      "Time", builder:valuebox {
        --width = BUTTON_WIDTH,
        min = 0,
        max = 15,
        value = self.time,
        notifier = function(value)
          self.time = value
        end
      }
    ),
    
    self:build_parameter_row(builder,
      "Repeat", builder:valuebox {
        --width = BUTTON_WIDTH,
        min = 0,
        max = 15,
        value = self.repeats,
        notifier = function(value)
          self.repeats = value
        end
      }
    )
  }
end


-- ============================================================

class 'DrumPatternArpeggiator' (DrumPatternEffect)

function DrumPatternArpeggiator:__init()
  DrumPatternEffect.__init(self, "Arpeggiate", 3, { 0, 0, 255 })
end

--------------------------------------------------------------
function DrumPatternArpeggiator:on_process(pattern,
                                           track,
                                           instrument,
                                           start_line,
                                           num_lines,
                                           line_index)
                                      
  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]
  local processor = self:get_processor()

  self:reset_notes_for_line(line)
  self:reset_effect_in_column(line, 1)
  
  if not processor.preserve_notes then
    line.note_columns[1].note_string = processor.base_note
    line.note_columns[1].volume_string = ".."
    line.note_columns[1].instrument_value = instrument
  end
  if line.note_columns[1].note_string ~= "---" then
    line.effect_columns[1].number_string = "00"
    line.effect_columns[1].amount_string = (line_index) .. line_index + 1
  end
end

--------------------------------------------------------------
function DrumPatternArpeggiator:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    
    self:build_default_controls(builder)
  }
end

-- ============================================================

class 'DrumPatternPitcher' (DrumPatternEffect)

function DrumPatternPitcher:__init()
  DrumPatternEffect.__init(self, "Pitch", 4, { 0, 255, 255 })
  self.direction = 1
  self.amount = 8
  self.increment = 1.0
end

--------------------------------------------------------------
function DrumPatternPitcher:on_process(pattern,
                                       track,
                                       instrument,
                                       start_line,
                                       num_lines,
                                       line_index)

  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]
  local processor = self:get_processor()

  local direction = "01"
  if self.direction == 2 then
    direction = "02"
  end

  self:reset_notes_for_line(line)
  self:reset_effect_in_column(line, 1)
  
  if line_index == 0 then
    if not processor.preserve_notes then
      line.note_columns[1].note_string = processor.base_note
      line.note_columns[1].volume_string = ".."
      line.note_columns[1].instrument_value = instrument
    end
  end
  line.effect_columns[1].number_string = direction 
  line.effect_columns[1].amount_value = math.min(255, math.max(1, math.max(self.amount * self.increment)))
  -- print ("processing " .. self.name .. " > " .. line_index .. " (" .. (start_line + line_index) .. ")")
end

--------------------------------------------------------------
function DrumPatternPitcher:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    
    self:build_default_controls(builder),
    
    self:build_parameter_row(builder,
      "Direction", builder:popup {
        --width = BUTTON_WIDTH,
        value = self.direction,
        items = {"Up", "Down"},
        notifier = function(new_index)
          self.direction = new_index
        end
      }
    ),
    
    self:build_parameter_row(builder,
      "Amount", builder:valuebox {
        --width = BUTTON_WIDTH,
        min = 1,
        max = 64,
        value = self.amount,
        notifier = function(value)
          self.amount = value
        end
      }
    ),
    
    self:build_parameter_row(builder,
      "Increment", builder:slider {
        --width = DEFAULT_CELL_WIDTH - TEXT_ROW_WIDTH,
        min = 1.0,
        max = 4.0,
        value = self.increment,
        notifier = function(value)
          self.increment = value
        end
      }
    )
  }
end


-- ============================================================

class 'DrumPatternReversor' (DrumPatternEffect)

--------------------------------------------------------------
function DrumPatternReversor:__init()
  DrumPatternEffect.__init(self, "Reverse", 5, { 255, 255, 0 })
end

--------------------------------------------------------------
function DrumPatternReversor:on_process(pattern,
                                        track,
                                        instrument,
                                        start_line,
                                        num_lines,
                                        line_index)

  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]
  local processor = self:get_processor()

  self:reset_notes_for_line(line)
  self:reset_effect_in_column(line, 1)
  
  if line_index == 0 then
    if not processor.preserve_notes then
      line.note_columns[1].note_string = processor.base_note
      line.note_columns[1].volume_string = ".."
      line.note_columns[1].instrument_value = instrument
    end
    line.effect_columns[1].number_string = "0B"
    line.effect_columns[1].amount_string = ".."
  elseif line_index == (num_lines - 1) then
    line.note_columns[1].note_string = processor.base_note
    line.note_columns[1].volume_string = ".."
    line.note_columns[1].instrument_value = instrument
    line.effect_columns[1].number_string = "1B"
    line.effect_columns[1].amount_string = ".."
  end
end

--------------------------------------------------------------
function DrumPatternReversor:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    
    self:build_default_controls(builder)
  }
end


-- ============================================================

class 'DrumPatternRandomic' (DrumPatternEffect)

--------------------------------------------------------------
function DrumPatternRandomic:__init()
  DrumPatternEffect.__init(self, "Random", 6, { 205, 155, 55 })
  self.last_effect = 0
  self.effect = nil
end

--------------------------------------------------------------
function DrumPatternRandomic:on_process(pattern,
                                        track,
                                        instrument,
                                        start_line,
                                        num_lines,
                                        line_index)

  local processor = self:get_processor()

  if line_index == 0 then
    self.last_effect = math.random(0, #processor:get_effects())
  end

  local effect = processor:get_effects()[self.last_effect]
  
  if effect ~= nil then
    effect:on_process(pattern,
                      track,
                      instrument,
                      start_line,
                      num_lines,
                      line_index)
  end
end

--------------------------------------------------------------
function DrumPatternRandomic:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    
    self:build_default_controls(builder)
  }
end


-- ============================================================

function show_help()

   local message = TOOL_NAME .. " v" .. TOOL_VERSION .. "\nby " .. TOOL_AUTHOR
   local title = "About"
   local buttons = {"OK"}

   renoise.app():show_prompt(title, message, buttons)
end


-- ============================================================

function show_dialog()

  -- the real thang
  
  local drum_processor = DrumPatternProcessor()
  
  drum_processor:add_effect(DrumPatternSlicer())
  drum_processor:add_effect(DrumPatternRepeater())
  drum_processor:add_effect(DrumPatternArpeggiator())
  drum_processor:add_effect(DrumPatternPitcher())
  drum_processor:add_effect(DrumPatternReversor())
  drum_processor:add_effect(DrumPatternRandomic())
  
  drum_processor:set_track_index(1)
  drum_processor:set_divisions(16)

  -- the views

  local vb = renoise.ViewBuilder()

  maindialog = renoise.app():show_custom_dialog(
    TOOL_NAME,
    vb:column {
      uniform = true,
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_MARGIN,

      vb:text { text = "Modules", font = "bold", align = "left" },
      drum_processor:build_effect_racks(vb),
     
      vb:text { text = "Sequencer", font = "bold", align = "left" },
      drum_processor:build_sequencer(vb),
     
      vb:text{ text = "Options", font = "bold", align = "left" },
      drum_processor:build_options(vb),
      
      vb:space{ height = 2 * DEFAULT_MARGIN },
      
      vb:horizontal_aligner {
        mode = "justify",
        
        vb:button {
          text = "Process",
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT,
          notifier = function ()
            drum_processor:process()
          end
        },

        vb:button {
           text = "?",
           width = HELP_BUTTON_WIDTH,
           height = BUTTON_HEIGHT,
           notifier = show_help
        },
      }
    }
  )
  
end

-- rprint(drum_processor:get_effects_name())
-- show_status( ipairs(effects))
