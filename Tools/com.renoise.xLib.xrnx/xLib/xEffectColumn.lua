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
        LOG("WARNING: Trying to write invalid value to effect column:",token,note_col[token])
      end
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
