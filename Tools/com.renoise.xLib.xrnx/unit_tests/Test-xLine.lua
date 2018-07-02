--[[ 

  Testcase for xLine

--]]

_xlib_tests:insert({
name = "xLine",
fn = function()

  --require (_xlibroot.."xNoteColumn")
  cLib.require (_xlibroot.."xLine")
  --require (_xlibroot.."xLinePattern")
  --require (_xlibroot.."xNoteColumn")
  --require (_xlibroot.."xEffectColumn")
  _trace_filters = {"^xLine*","^xLinePattern*","^xNoteColumn*","^xEffectColumn*"}

  LOG(">>> xLine: starting unit-test...")

  local xline,xline2,xline_def

  -- using table as constructor argument

  xline_def = {
    note_columns = {
      {
        note_value = 48
      }
    },
    effect_columns = {
      {
        number_string = "0S",
        amount_string = "80"
      }
    }
  }

  xline = xLine(xline_def)
  assert(type(xline)=="xLine")
  assert(#xline.note_columns == 1)
  assert(xline.note_columns[1].note_string == "C-4")
  assert(xline.note_columns[1].note_value == 48)
  assert(#xline.effect_columns == 1)
  assert(xline.effect_columns[1].number_string == "0S")
  assert(xline.effect_columns[1].amount_string == "80")

  xline_def.note_columns = {}
  assert(#xline.note_columns == 1)
  assert(xline.note_columns[1].note_string == "C-4")
  assert(xline.note_columns[1].note_value == 48)

  xline = xLine(xline_def)
  assert(type(xline)=="xLine")
  assert(#xline.note_columns == 0)
  assert(#xline.effect_columns == 1)
  assert(xline.effect_columns[1].number_string == "0S")
  assert(xline.effect_columns[1].amount_string == "80")

  -- confirm that constructor table is dereferenced 

  xline_def.note_columns = {
    {
      note_value = 48
    }     
  }
  assert(#xline.note_columns == 0)

  -- trying to assign invalid value 

  local success,err = pcall(function()
    xline.effect_columns[1].number_string = "foo"
  end)
  assert(success == false)

  -- using instance as constructor argument  
  -- (ensure that values are copied, not a reference)
  
  xline = xLine(xline_def)
  assert(xline.note_columns[1].note_value == 48)
  xline2 = xLine(xline)
  xline.note_columns[1].note_value = 42
  assert(xline.note_columns[1].note_value == 42)
  assert(xline2.note_columns[1].note_value == 48)

  -- testing sparse note-columns 

  xline_def = {
    note_columns = {}
  }
  xline_def.note_columns[1] = {note_value = 1}
  xline_def.note_columns[4] = {note_value = 4}
  xline_def.note_columns[5] = {note_value = 5}

  xline = xLine(xline_def)
  assert(#xline.note_columns == 5)
  assert(xline.note_columns[1].note_value == 1)
  assert(xline.note_columns[2].note_value == nil)
  assert(xline.note_columns[3].note_value == nil)
  assert(xline.note_columns[4].note_value == 4)
  assert(xline.note_columns[5].note_value == 5)
  
  -- testing sparse effect-columns 

  xline_def = {
    effect_columns = {}
  }
  xline_def.effect_columns[1] = {number_string = "0S", amount_string = "81"}
  xline_def.effect_columns[4] = {number_string = "0S", amount_string = "84"}
  xline_def.effect_columns[5] = {number_string = "0S", amount_string = "85"}

  xline = xLine(xline_def)
  assert(xline.effect_columns[1].amount_string == "81")
  assert(xline.effect_columns[2].amount_string == nil)
  assert(xline.effect_columns[3].amount_string == nil)
  assert(xline.effect_columns[4].amount_string == "84")
  assert(xline.effect_columns[5].amount_string == "85")
  
  -- out of range columns 
  -- should create a bunch of empty columns, 
  -- but ignore the out-of-range ones...

  xline_def = {
    note_columns = {},
    effect_columns = {},
  }
  xline_def.note_columns[42] = {note_value = 1}
  xline_def.effect_columns[14] = {number_string = "0S", amount_string = "81"}

  xline = xLine(xline_def)
  assert(#xline.note_columns == xLinePattern.MAX_NOTE_COLUMNS)
  assert(#xline.effect_columns == xLinePattern.MAX_EFFECT_COLUMNS)

  LOG(">>> xLine: OK - passed all tests")

end
})
