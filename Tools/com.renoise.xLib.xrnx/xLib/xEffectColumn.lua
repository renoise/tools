--[[============================================================================
xEffectColumn
============================================================================]]--
--[[

  This class is representing renoise.EffectColumn
  Unlike the renoise.EffectColumn, this one can be freely defined, 
  without the need to have the line present in an actual song 

  TODO additional instructions: add, sub, mul, div... 

]]

class 'xEffectColumn'

xEffectColumn.tokens = {
    "number_value","number_string", 
    "amount_value","amount_string",
}

-------------------------------------------------------------------------------
-- constructor
-- @param args (table), e.g. {number_string="0S",amount_value=0x40}

function xEffectColumn:__init(args)

  for token,value in pairs(args) do
    if (table.find(xEffectColumn.tokens,token)) then
      self[token] = args[token]
    end
  end

end

-------------------------------------------------------------------------------
-- @param fx_col (renoise.EffectColumn)
-- @param tokens (table<xStreamModel.output_tokens>)
-- @param clear_undefined (bool)

function xEffectColumn:do_write(fx_col,tokens,clear_undefined)

  for k,token in ipairs(tokens) do
    if self["do_write_"..token] then
      local success = pcall(function()
        self["do_write_"..token](self,fx_col,clear_undefined)
      end)
      if not success then
         LOG("WARNING: xEffectColumn - Trying to write invalid value to property:",token,self[token])
       --[[
        if not fix_out_of_range then
          LOG("WARNING: xEffectColumn - Trying to write invalid value to property:",token,self[token])
        else
          -- restricting to range only works with values
          -- let's just assume that out-of-range errors are unlikely
          -- so we can avoid these expensive checks for every write
          LOG("WARNING: xEffectColumn - Trying to write invalid value, attempting to fix")
          success = pcall(function()
            --print("xNoteColumn:do_write",token)
            self["do_fix_"..token](self,fx_col)
          end)
          if not success then
            LOG("WARNING: xEffectColumn - Failed to fix value for property:",token,self[token])
          end
        end
        ]]
      end
    --else
    --  LOG("WARNING: xEffectColumn - Trying to assign value to non-existing property:",token)
    end
  end

end

-------------------------------------------------------------------------------
-- we need a function for each possible token

function xEffectColumn:do_write_number_value(fx_col,clear_undefined)
  if self.number_value then 
    fx_col.number_value = self.number_value
  elseif clear_undefined then
    fx_col.number_value = 0
  end
end

--[[
function xEffectColumn:do_fix_number_value(fx_col)
  if self.number_value < 0 then
    fx_col.number_value = 0
  elseif self.number_value > 291 then
    fx_col.number_value = 291
  elseif self.number_value < 256 then
    fx_col.number_value = 256
    -- allowed value are between 0-35, or 256-291
    -- between 35 and 256 are a bit fuzzy here, but what to do? 
  end
end
]]

function xEffectColumn:do_write_number_string(fx_col,clear_undefined)
  if self.number_string then 
    fx_col.number_string = self.number_string
  elseif clear_undefined then
    fx_col.number_string = xLinePattern.EMPTY_STRING
  end
end

function xEffectColumn:do_write_amount_value(fx_col,clear_undefined)
  if self.amount_value then 
    fx_col.amount_value = self.amount_value
  elseif clear_undefined then
    fx_col.amount_value = 0
  end
end
--[[
function xEffectColumn:do_fix_amount_value(fx_col)
  if self.amount_value > 255 then 
    note_col.amount_value = 255
  elseif self.amount_value < 0 then 
    note_col.amount_value = 0
  end
end
]]

function xEffectColumn:do_write_amount_string(fx_col,clear_undefined)
  if self.amount_string then 
    fx_col.amount_string = self.amount_string
  elseif clear_undefined then
    fx_col.amount_string = xLinePattern.EMPTY_STRING
  end
end

-------------------------------------------------------------------------------
-- @param fx_col (renoise.EffectColumn)
-- @return table 

function xEffectColumn.do_read(fx_col)
  TRACE("xEffectColumn.do_read(fx_col)")

  local rslt = {}
  for k,v in ipairs(xEffectColumn.tokens) do
    rslt[v] = fx_col[v]
  end

  return rslt

end


-------------------------------------------------------------------------------

function xEffectColumn:__tostring()

  return "xEffectColumn"

end
