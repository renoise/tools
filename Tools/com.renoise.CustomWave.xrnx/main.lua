--[[============================================================================
main.lua
============================================================================]]--

-- locals

SAMPLE_BIT_DEPTH = 32
SAMPLE_FREQUENCY = 44100 --this should be set to the driver' sample rate
SAMPLE_CHANS = 1
  
OPERATORS = 6

WAVE_NONE = 1
WAVE_ARCCOSINE = WAVE_NONE + 1
WAVE_ARCSINE = WAVE_ARCCOSINE + 1
WAVE_COSINE = WAVE_ARCSINE + 1
WAVE_MORPHER = WAVE_COSINE + 1
WAVE_NOISE = WAVE_MORPHER + 1
WAVE_PULSE = WAVE_NOISE + 1
WAVE_SAW = WAVE_PULSE + 1
WAVE_SINE =WAVE_SAW + 1
WAVE_SQUARE = WAVE_SINE + 1
WAVE_TANGENT = WAVE_SQUARE + 1
WAVE_TRIANGLE = WAVE_TANGENT + 1
WAVE_VARIATOR = WAVE_TRIANGLE + 1
WAVE_WAVETABLE = WAVE_VARIATOR + 1
WAVE_NUMBER = WAVE_WAVETABLE

EPSILON = 1e-12
MINUSINFDB = -200.0

real_amplification = 1.0
int_start_note = 58 --A-4
int_end_note = 58 --A-4
int_wave_type_selected = 5 --Sine
int_operator_selected = 1
int_frames = 0
int_frame = 0
real_cycles = 1
real_last_frame_value = 0

local buffer_new

TWOPI = 2*math.pi
PI = math.pi
HALFPI = PI * 0.5
NOTE_BASE = math.pow(2,1/12)


--------------------------------------------------------------------------------
-- requires
--------------------------------------------------------------------------------

require "gui"
require "operators"


--------------------------------------------------------------------------------
-- globals
--------------------------------------------------------------------------------

notifiers = {}

array_string_operators = 
{
  "-NONE-",
  "Arc Cosine", 
  "Arc Sine", 
  "Cosine",
  "Morpher",  
  "Noise", 
  "Pulse", 
  "Saw", 
  "Sine", 
  "Square", 
  "Tangent",
  "Triangle",
  "Variator",
  "Wave"
}
  
array_function_operators = 
{
  none,
  arccosine,
  arcsine,
  cosine,
  morpher,
  noise,
  pulse,
  saw,
  sine,
  square,
  tangent,
  triangle,
  variator,
  wave
}
  
array_real_amplitudes = {}
array_variant_parameters = {}
array_instrument_number = {} -- to be used with WAVE operator
array_sample_number = {} -- to be used with WAVE operator
array_boolean_inverts = {}
array_int_modulators = {}
array_real_frequency_multipliers = {}
array_morphing_times = {}
array_waves = {}
array_operator_last_values = {}

toggle_auto_generate = false;


--------------------------------------------------------------------------------
-- menu registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Sample Editor:Generate Custom Wave...",
  invoke = function() show_dialog() end
}


--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

function note_to_frequency(int_start_note)
  return 440 * math.pow(NOTE_BASE,(int_start_note-58))
end

--------------------------------------------------------------------------------

function convert_linear_to_db(real_value)
  if (real_value > EPSILON) then
    return math.log10(real_value) * 20.0
  else
    return MINUSINFDB
  end
end


--------------------------------------------------------------------------------

function convert_db_to_linear(real_value)
  if (real_value > MINUSINFDB) then
    return math.pow(10.0, real_value * 0.05)
  else
    return 0.0
  end
end


--------------------------------------------------------------------------------
-- data processing
--------------------------------------------------------------------------------

function wave_is_set(int_wave)

  return
    array_waves[int_wave] and 
    array_real_amplitudes[int_wave] and 
    (array_variant_parameters[int_wave] ~= nil or 
     array_instrument_number[int_wave]) and 
    array_waves[int_wave] ~= WAVE_NONE
    
end


--------------------------------------------------------------------------------

function initialize_wave(int_wave_number)
  array_waves[int_wave_number] = WAVE_NONE
  array_real_amplitudes[int_wave_number] = 1
  array_variant_parameters[int_wave_number] = 0.5
  array_boolean_inverts[int_wave_number] = false
  array_real_frequency_multipliers[int_wave_number] = 1.0
  array_int_modulators[int_wave_number] = 0
  array_instrument_number[int_wave_number] = 0
  array_sample_number[int_wave_number] = 0  
  array_morphing_times[int_wave_number] = 1
  array_operator_last_values[int_wave_number] = 0
  vb.views.cmbModulate.active = true
end


--------------------------------------------------------------------------------

--returns:
--*a boolean which indicates is int_operator is modulated by any operator
--*an array which contains the modulators of int_operator 
--*an integer number indicating how many modulators there are for int_operator
function is_modulated(int_operator)

  local int_count
  local int_mod = 0
  local array_int_return = {}
  for int_count = 1,OPERATORS do
    if array_int_modulators[int_count] == int_operator then
      int_mod = int_mod + 1
      array_int_return[int_mod] = int_count
    end
  end
  
  return int_mod > 0, array_int_return, int_mod
  
end

--------------------------------------------------------------------------------

function is_modulated_by(int_modulated, int_modulator)

  return array_int_modulators[int_modulator] == int_modulated

end

--------------------------------------------------------------------------------

function can_modulate(int_wannabe_modulator)

  if int_wannabe_modulator == nil then
    return false
  end

  local bool_is_set = wave_is_set(int_wannabe_modulator)
  local bool_is_active = array_waves[int_wannabe_modulator] ~= WAVE_NONE
  local bool_is_not_modulator = not is_modulator(int_wannabe_modulator) 
  
  --[[print("Can OP#" .. int_wannabe_modulator .. " be a modulator?", 
    "is set: ", bool_is_set, 
      "is active: ", bool_is_active, 
    "is not a modulator: ", bool_is_not_modulator
  )]]--
  
  return 
    bool_is_set and 
    bool_is_active and 
    true --bool_is_not_modulator

end


--------------------------------------------------------------------------------

function can_be_modulated(int_wannabe_modulated)

  if int_wannabe_modulated == nil then
    return false
  end

  local bool_is_not_current_operator = int_wannabe_modulated ~= int_operator_selected
  local bool_is_set = wave_is_set(int_wannabe_modulated)
  local bool_is_active = array_waves[int_wannabe_modulated] ~= WAVE_NONE
  local bool_is_modulator, int_modulator = is_modulator(int_wannabe_modulated) 
  local bool_is_not_modulated = not is_modulated(int_wannabe_modulated) 
  
  --[[print("Can OP#" .. int_wannabe_modulated .. " be a modulator?", 
    "is not the current operator: ", bool_is_not_current_operator,
    "is set: ", bool_is_set, 
      "is active: ", bool_is_active, 
    "is not a modulator: ", bool_is_not_modulator,
    "is not already modulated: ", bool_is_not_modulated
  )]]--
  
  return 
    bool_is_not_current_operator and 
    bool_is_set and 
    bool_is_active and 
    not (bool_is_modulator or array_waves[array_int_modulators[int_modulator]] == WAVE_MORPHER) and
    bool_is_not_modulated

end

--------------------------------------------------------------------------------

-- returns:
-- *a boolean indicating if int_operator modulates another operator
-- *an integer value indicating the operator being modulated by int_operator
function is_modulator(int_operator)

  local bool_is_modulator = array_int_modulators[int_operator] and 
    array_int_modulators[int_operator] > 0
  
  local int_modulated = 0
  
  if bool_is_modulator then
    int_modulated = array_int_modulators[int_operator]
  end
  
  return bool_is_modulator, int_modulated

end


--------------------------------------------------------------------------------

function operate(int_wave,real_x)

  local real_phase = real_x

  if array_real_frequency_multipliers[int_wave] then 
  
    if array_waves[int_wave] == WAVE_VARIATOR then

      real_phase = math.random() < array_real_frequency_multipliers[int_wave]
    --print("Will variator signal change?", real_phase)
    
    else

      real_phase = 
        math.fmod(real_x * array_real_frequency_multipliers[int_wave],1.01) 
    
    --print(real_phase,real_x,array_real_frequency_multipliers[int_wave])
    
  end
  
  end

  local real_amplitude = array_real_amplitudes[int_wave]
  local variant_parameter = array_variant_parameters[int_wave]
  
  local real_operator_value
  
  if array_waves[int_wave] then  
     real_operator_value = 
       array_function_operators[array_waves[int_wave]](
         real_amplitude,
         variant_parameter,
         real_phase
       )
  else
    real_operator_value = 0
  end

  if array_boolean_inverts[int_wave] then 
    real_operator_value = -1 * real_operator_value 
  end
  
  return real_operator_value
  
end


--------------------------------------------------------------------------------

function process_data(real_amplification,real_x)

  local int_wave
  local int_valid_waves = 0
  local real_frame_value = 0
  
  for int_wave = 1, OPERATORS do
  
  ----print(array_string_operators[array_waves[int_wave]])
  
  local bool_variant_parameters_are_ok = true
  
  if 
    array_waves[int_wave] == WAVE_WAVETABLE and 
    array_instrument_number[int_wave] > 0 and 
    array_sample_number[int_wave] > 0 
  then
    -- for WAVE mode, get the latest sample buffer
    array_variant_parameters[int_wave] = 
    renoise.song().instruments[array_instrument_number[int_wave]]
    .samples[array_sample_number[int_wave]]
      .sample_buffer
  
  elseif array_waves[int_wave] == WAVE_VARIATOR then
    -- for VARIATOR mode, take the last frame value
      array_variant_parameters[int_wave] = array_operator_last_values[int_wave]
  
    elseif array_waves[int_wave] == WAVE_MORPHER then
  
    -- for MORPHER mode, take its two modulation sources and the morphing time
    
      local bool_is_modulated, arr_int_modulators, int_modulators = is_modulated(int_wave)
      
      if 
        not bool_is_modulated or int_modulators ~= 2 
      then
        bool_variant_parameters_are_ok = false
      else
    
        local real_morphing_time = array_morphing_times[int_wave]
        array_variant_parameters[int_wave] =
         {operate(arr_int_modulators[1],real_x),operate(arr_int_modulators[2],real_x)}
        real_x = math.min(1,int_frame / (buffer_new.number_of_frames * real_morphing_time))
        -- print("OP#" .. int_wave .. ": morphing OP#" .. arr_int_modulators[1] .. " into OP#" .. arr_int_modulators[2], real_x, int_frame)
      
      end
    
    end

    local bool_wave_is_set = wave_is_set(int_wave)
    local bool_wave_is_active = bool_wave_is_set and array_waves[int_wave] > 0
    local bool_is_not_modulator = is_modulator(int_wave) == false
  
  --[[--print("can OP#" .. int_wave .. " be processed?",
    "Variant parameters are ok:", bool_variant_parameters_are_ok,
    "Wave is set", bool_wave_is_set,
    "Wave is active", bool_wave_is_active,
    "Is not a modulator", bool_is_not_modulator)]]--
  
    if bool_variant_parameters_are_ok and
      bool_wave_is_set and 
      bool_wave_is_active and 
      bool_is_not_modulator 
    then
    
      local real_modulator = 0.0
      local bool_is_modulated, array_modulators, int_modulators = is_modulated(int_wave)
    
      if 
        bool_is_modulated and array_waves[int_wave] ~= WAVE_MORPHER 
      then
        -- modulate the amplitude of the current operator by the 
        -- operators which are assigned to it 
        local int_modulator
        local array_real_modulators = {}
        local int_count = 0
    
        for int_modulator = 1, int_modulators do
   
          int_count = int_count + 1
          local int_wave_mod = array_modulators[int_modulator]

          --print("modulating amplitude of OP#" .. int_wave .. " with OP#" .. int_wave_mod)

          array_real_modulators[int_count] = 
            array_real_amplitudes[int_wave] * operate(int_wave_mod,real_x)
          
        end

        for int_modulator = 1, int_modulators do
          real_modulator = real_modulator + 
            array_real_modulators[int_modulator]
        end
        
        real_modulator = real_modulator / int_modulators

      end
    
      local real_operator_value = operate(int_wave,real_x)
    
      array_operator_last_values[int_wave] = real_operator_value
        
      real_frame_value = real_frame_value + 
      real_operator_value * (1 + real_modulator)
        
      int_valid_waves = int_valid_waves + 1
            
    end
  
  end

  ----print("------")
  
  if int_valid_waves > 0 then
    real_frame_value = real_amplification * 
    real_frame_value / int_valid_waves
  end
  
  return real_frame_value, int_valid_waves

end


--------------------------------------------------------------------------------

function generate()

  local instrument = renoise.song().selected_instrument
  local sample_new
  local int_sample_index = renoise.song().selected_sample_index
  local int_generated_samples = 0

  while table.getn(instrument.samples) > 0 do
    instrument:delete_sample_at(1)
  end
  
  for int_operator_to_which_reset_last_value = 1, OPERATORS do
    array_operator_last_values[int_operator_to_which_reset_last_value] = 0
  end  
 
  
  for int_note = int_start_note, int_end_note do

    sample_new = instrument:insert_sample_at(int_generated_samples+1) 

  
    buffer_new = sample_new.sample_buffer
  
    int_frames = SAMPLE_FREQUENCY / note_to_frequency(int_note) 
     
    -- if the samples is "the same" (size wise), don't recreate it, just overwrite it
    if buffer_new.has_sample_data
      and buffer_new.number_of_frames == math.floor(real_cycles*int_frames)
      and buffer_new.sample_rate == SAMPLE_FREQUENCY
      and buffer_new.bit_depth == SAMPLE_BIT_DEPTH
      and buffer_new.number_of_channels == SAMPLE_CHANS
    then
      -- do nothing
    else
      --create the new sample
      if 
        int_frames > 0 and 
        not buffer_new:create_sample_data(
          SAMPLE_FREQUENCY, 
          SAMPLE_BIT_DEPTH, 
          SAMPLE_CHANS, 
          real_cycles*int_frames
        )
      then
        renoise.app():show_error("Error during sample creation!")
        renoise.song():undo()
        return
      end
    end
     
    buffer_new:prepare_sample_data_changes()
  
    local int_chan,real_frame_value,int_valid_waves
    for int_chan = 1, SAMPLE_CHANS do
      for int_frame_in_buffer = 1, buffer_new.number_of_frames do
        int_frame = int_frame_in_buffer
        real_frame_value, int_valid_waves = 
          process_data(real_amplification,int_frame_in_buffer/int_frames)
        buffer_new:set_sample_data(int_chan,int_frame_in_buffer,real_frame_value)
        real_last_frame_value = real_frame_value
      end
    end
  
    buffer_new:finalize_sample_data_changes()
  
--    sample_new.base_note = int_note - 1  //removed in v2.8
    sample_new.name = "Generated " .. note_number_to_string(int_note) .. " sample"
  
    int_generated_samples = int_generated_samples + 1
  end
  
  --set instrument name
  instrument.name = "Generated instrument"
  
  --create key zones
  
  for int_note = int_start_note, int_end_note do
    local sample_index = int_note - int_start_note + 1
    
    local base_note = int_note - 1 
    
    local note_range = {0, 119}
    
    if (int_note > int_start_note) then
      note_range[1] = int_note - 1
    end    
    if (int_note < int_end_note) then
      note_range[2] = int_note - 1
    end

    local sample = instrument.samples[sample_index]

    sample.sample_mapping.layer = renoise.Instrument.LAYER_NOTE_ON
    sample.sample_mapping.note_range = note_range
    sample.sample_mapping.base_note = base_note

  end
end

