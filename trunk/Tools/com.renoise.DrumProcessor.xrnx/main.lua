-- ============================================================

--  consts

local TOOL_NAME = "Drum Processor"

local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

local BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
local BUTTON_WIDTH = 86
local SEQUENCER_BUTTON_SIZE = 32
local HELP_BUTTON_WIDTH = 10

local POPUP_WIDTH = 2*BUTTON_WIDTH - 2*DEFAULT_MARGIN

local NOTE_WIDTH = 40
local NUMBER_WIDTH = 30
local DEFAULT_CELL_WIDTH = 180
local TEXT_ROW_WIDTH = 66


--  locals

local maindialog = nil


-- functions

local function show_status(message)
  renoise.app():show_status(message); print(message)
end

local function keys(t)
  local keytable = {}
  for k,v in pairs(t) do table.insert(keytable, k) end
  return keytable
end


-- ============================================================

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

function DrumPatternProcessor:__init()
  self.effects = {}
  self.track_index = 1
  self.instrument_index = 0
  self.instrument_type = 0
  self.base_note = "C-4"
  self.preserve_notes = false
  self.play_pos = 0
  self.selected_fx = 0
  self.sequencer = {}

  self:set_divisions(16)
end

function DrumPatternProcessor:add_effect(effect)
  effect:set_processor(self)
  table.insert(self.effects, effect)
end

function DrumPatternProcessor:get_effect(index)
  return self.effects[index]
end

function DrumPatternProcessor:get_effects(name)
  return self.effects
end

function DrumPatternProcessor:get_effects_name()
  local names = {}
  for k,v in pairs(self.effects) do
    table.insert(names, v.name)
  end
  return names
end

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

function DrumPatternProcessor:set_divisions(divisions)
  if (divisions >= 1 and divisions < 32) then
    self.divisions = divisions
    self:on_update_sequencer()
  else
    renoise.app():show_warning("Cannot select " .. divisions .. " divisions!")     
  end
end

function DrumPatternProcessor:clear(track, pattern)
  renoise.song().patterns[pattern].tracks[track]:clear()
end

function DrumPatternProcessor:process()

  local song = renoise.song()
  local track = self.track_index
  local pattern = song.selected_pattern_index
  local instrument = self.instrument_index
  local type = self.instrument_type
  local basenote = self.base_note
  local length = self.effect_length
  
  local pos = 0
  local lines = song.patterns[pattern].number_of_lines

  local max_length = lines / self.divisions
  local max_ilength = math.floor(max_length + 0.5)

  local fx = nil
  local currentfx = 0
  local currentfxindex = 0
  
  -- clear track (TODO: don't do it, let the effect handle this)
  self:clear(pattern, track)
  -- reset sequencer position
  self.play_pos = 0
  
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
                    instrument,
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

function DrumPatternProcessor:on_update_sequencer()
  if #self.sequencer < self.divisions then
    local new_table_size = (self.divisions - #self.sequencer)
    for numstep = 1,new_table_size do
      table.insert(self.sequencer, 0)
    end
  end
end

function DrumPatternProcessor:build_effect_racks(builder)
  return builder:column {
    margin = DEFAULT_MARGIN,
    spacing = DEFAULT_SPACING,
    builder:row {
      spacing = DEFAULT_SPACING,
      self.effects[1]:on_build_view(builder),
      self.effects[2]:on_build_view(builder),
      self.effects[3]:on_build_view(builder),
      self.effects[4]:on_build_view(builder),
      self.effects[5]:on_build_view(builder)
    },
    self:build_sequencer(builder)
  }
end

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
        color = {0, 0, 0},
        notifier = function ()
          local button = builder.views["__SEQ__" .. numstep]
          if self.selected_fx == 0 or self.sequencer[numstep] == self.selected_fx then
            button.color = { 0, 0, 0 }
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

-- ============================================================

class 'DrumPatternEffect'

function DrumPatternEffect:__init(name, column, color)
  self.name = name
  self.column = column
  self.processor = nil
  self.color = color
end

function DrumPatternEffect:set_processor(processor)
  self.processor = processor
end

function DrumPatternEffect:reset_notes_for_line(line)
  if not self.processor.preserve_notes then
    for _,col in pairs(line.note_columns) do
      col.note_string = "---"
      col.volume_string = ".."
      col.instrument_string = ".."  
    end
  end
end

function DrumPatternEffect:reset_effects_for_line(line)
  for _,col in pairs(line.effect_columns) do
    col.number_string = ".."
    col.amount_string = ".."  
  end
end

function DrumPatternEffect:reset_effect_in_column(line, col)
  line.effect_columns[col].number_string = ".."
  line.effect_columns[col].amount_string = ".."  
end

function DrumPatternEffect:build_default_controls(builder)
  return builder:row {
    width = DEFAULT_CELL_WIDTH,
    builder:text {
      width = TEXT_ROW_WIDTH,
      text = self.name
    },
    builder:button {
      width = DEFAULT_CELL_WIDTH - TEXT_ROW_WIDTH,
      id = "__FXBUTTON__" .. self.column,
      notifier = function()
        local button = builder.views["__FXBUTTON__" .. self.column]
        for view = 1,#self.processor.effects do
          builder.views["__FXBUTTON__" .. view].color = { 0, 0, 0 }
        end
        if self.processor.selected_fx == self.column then
          self.processor.selected_fx = 0
        else
          self.processor.selected_fx = self.column
          button.color = self.color
        end
      end
    }
  }
end

function DrumPatternEffect:on_build_view(builder)
  assert(false) -- cannot use this directly !
end

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

function DrumPatternSlicer:__init()
  DrumPatternEffect.__init(self, "Slice", 1, { 255, 0, 0 })
  self.random = true
  self.offset = 0
end

function DrumPatternSlicer:on_process(pattern,
                                      track,
                                      instrument,
                                      start_line,
                                      num_lines,
                                      line_index)

  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]

  self:reset_notes_for_line(line)
  self:reset_effect_in_column(line, 1)
  
  if line_index == 0 then
    if not self.processor.preserve_notes then
      line.note_columns[1].note_string = self.processor.base_note
      line.note_columns[1].volume_string = ".."
      line.note_columns[1].instrument_value = self.processor.instrument_index
    end
    if line.note_columns[1].note_string ~= "---" then
      line.effect_columns[1].number_value = 0x09
      if self.random then
        line.effect_columns[1].amount_value =
          ((self.offset + math.random (0, 15)) % 16) * 16
      else
        line.effect_columns[1].amount_value =
          (((start_line + line_index) / num_lines + self.offset) % 16) * 16
      end
    end
  end
end

function DrumPatternSlicer:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    self:build_default_controls(builder),
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Random"
      },
      builder:checkbox {
        value = self.random,
        notifier = function(value)
          self.random = value
        end
      }
    },
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Offset"
      },
      builder:slider {
        width = DEFAULT_CELL_WIDTH - TEXT_ROW_WIDTH,
        min = 0,
        max = 15,
        value = 0,
        notifier = function(value)
          self.offset = value
        end
      }
    }

  }
end


-- ============================================================

class 'DrumPatternRepeater' (DrumPatternEffect)

function DrumPatternRepeater:__init()
  DrumPatternEffect.__init(self, "Repeat", 2, { 0, 255, 0 })
  self.time = "0"
  self.repeats = "0"
end

function DrumPatternRepeater:on_process(pattern,
                                        track,
                                        instrument,
                                        start_line,
                                        num_lines,
                                        line_index)
 
  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]

  if not self.processor.preserve_notes then
    self:reset_notes_for_line(line)
    self:reset_effect_in_column(line, 1)
    
    line.note_columns[1].note_string = self.processor.base_note
    line.note_columns[1].volume_string = ".."
    line.note_columns[1].instrument_value = self.processor.instrument_index
  end
  if line.note_columns[1].note_string ~= "---" then
    line.effect_columns[1].number_string = "0E"
    line.effect_columns[1].amount_string = self.time .. self.repeats
  end
end

function DrumPatternRepeater:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    self:build_default_controls(builder),
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Random"
      }, 
      builder:checkbox {
        value = self.random,
        notifier = function(value)
          self.random = value
        end
      }
    },
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Time"
      },
      builder:valuebox {
        width = BUTTON_WIDTH,
        min = 0,
        max = 15,
        value = 0,
        notifier = function(value)
          self.time = string.format("%x", value)
        end
      }
    },
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Repeat"
      },
      builder:valuebox {
        width = BUTTON_WIDTH,
        min = 0,
        max = 15,
        value = 0,
        notifier = function(value)
          self.repeats = string.format("%x", value)
        end
      }
    }
  }
end


-- ============================================================

class 'DrumPatternArpeggiator' (DrumPatternEffect)

function DrumPatternArpeggiator:__init()
  DrumPatternEffect.__init(self, "Arpeggiate", 3, { 0, 0, 255 })
end

function DrumPatternArpeggiator:on_process(pattern,
                                           track,
                                           instrument,
                                           start_line,
                                           num_lines,
                                           line_index)
                                      
  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]

  self:reset_notes_for_line(line)
  self:reset_effect_in_column(line, 1)
  
  if not self.processor.preserve_notes then
    line.note_columns[1].note_string = self.processor.base_note
    line.note_columns[1].volume_string = ".."
    line.note_columns[1].instrument_value = self.processor.instrument_index
  end
  if line.note_columns[1].note_string ~= "---" then
    line.effect_columns[1].number_string = "00"
    line.effect_columns[1].amount_string = (line_index) .. line_index + 1
  end
end

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

function DrumPatternPitcher:on_process(pattern,
                                       track,
                                       instrument,
                                       start_line,
                                       num_lines,
                                       line_index)

  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]

  local direction = "01"
  if self.direction == 2 then
    direction = "02"
  end

  self:reset_notes_for_line(line)
  self:reset_effect_in_column(line, 1)
  
  if line_index == 0 then
    if not self.processor.preserve_notes then
      line.note_columns[1].note_string = self.processor.base_note
      line.note_columns[1].volume_string = ".."
      line.note_columns[1].instrument_value = self.processor.instrument_index
    end
  end
  line.effect_columns[1].number_string = direction 
  line.effect_columns[1].amount_value = math.min(255, math.max(1, math.max(self.amount * self.increment)))
  -- print ("processing " .. self.name .. " > " .. line_index .. " (" .. (start_line + line_index) .. ")")
end

function DrumPatternPitcher:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    self:build_default_controls(builder),
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Direction"
      },
      builder:popup {
        width = BUTTON_WIDTH,
        value = self.direction,
        items = {"Up", "Down"},
        notifier = function(new_index)
          self.direction = new_index
        end
      }
    },
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Amount"
      },
      builder:valuebox {
        width = BUTTON_WIDTH,
        min = 1,
        max = 64,
        value = self.amount,
        notifier = function(value)
          self.amount = value
        end
      }
    },
    builder:row {
      width = DEFAULT_CELL_WIDTH,
      builder:text {
        width = TEXT_ROW_WIDTH,
        text = "Increment"
      },
      builder:slider {
        width = DEFAULT_CELL_WIDTH - TEXT_ROW_WIDTH,
        min = 1.0,
        max = 4.0,
        value = self.increment,
        notifier = function(value)
          self.increment = value
        end
      }
    }

  }
end


-- ============================================================

class 'DrumPatternReversor' (DrumPatternEffect)

function DrumPatternReversor:__init()
  DrumPatternEffect.__init(self, "Reverse", 5, { 255, 255, 0 })
end

function DrumPatternReversor:on_process(pattern,
                                        track,
                                        instrument,
                                        start_line,
                                        num_lines,
                                        line_index)

  local line = renoise.song().patterns[pattern].tracks[track].lines[start_line + line_index]

  self:reset_notes_for_line(line)
  self:reset_effect_in_column(line, 1)
  
  if line_index == 0 then
    if not self.processor.preserve_notes then
      line.note_columns[1].note_string = self.processor.base_note
      line.note_columns[1].volume_string = ".."
      line.note_columns[1].instrument_value = self.processor.instrument_index
    end
    line.effect_columns[1].number_string = "0B"
    line.effect_columns[1].amount_string = ".."
  elseif line_index == (num_lines - 1) then
    line.note_columns[1].note_string = self.processor.base_note
    line.effect_columns[1].number_string = "1B"
    line.effect_columns[1].amount_string = ".."
  end
end

function DrumPatternReversor:on_build_view(builder)
  return builder:column {
    style = "group",
    margin = DEFAULT_MARGIN,
    uniform = true,
    self:build_default_controls(builder)
  }
end


-- ============================================================

function show_help()

   local help_message = [[ Some help here !]]
   local title = TOOL_NAME
   local buttons = {"OK"}

   renoise.app():show_prompt(title, help_message, buttons)
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
  
  drum_processor:set_track_index(1)
  drum_processor:set_divisions(16)

  -- the views

  local vb = renoise.ViewBuilder()

  maindialog = renoise.app():show_custom_dialog(
    TOOL_NAME,
    vb:column {
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_MARGIN,
      uniform = true,

--[[
      vb:row {
        style = "group",
        margin = DEFAULT_MARGIN,
        spacing = DEFAULT_SPACING,  
        vb:switch {
          id = "switch",
          width = 2 * DEFAULT_MARGIN
            + (2 * DEFAULT_MARGIN + DEFAULT_CELL_WIDTH)
            * #drum_processor.effects,
          value = 1,
          items = drum_processor:get_effects_name(),
          notifier = function(new_index)
            local switch = vb.views.switch
            show_status(("switch value changed to '%s'"):
              format(switch.items[new_index]))
          end
        }
      },
]]--      
      drum_processor:build_effect_racks(vb),
      
      vb:row {
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
           notifier = show_help
        }
      }
    }
  )
  
end

-- rprint(drum_processor:get_effects_name())
-- show_status( ipairs(effects))
