--[[============================================================================
vLogView
============================================================================]]--

require (_vlibroot.."vCompositeControl")

class 'vLogView' (vCompositeControl)

--------------------------------------------------------------------------------
--- Simple log display with add() and replace() methods

vLogView.DEFAULT_W = 100
vLogView.DEFAULT_H = 60

vLogView.VIEWS = {
  'clear_button',
}

function vLogView:__init(...)

  local args = cLib.unpack_args(...)

  -- properties --

  --- (string) all text in the log 
  self.text = property(self.get_text,self.set_text)

  --- (bool) when true, scroll to bottom when adding text
  self.autoscroll = args.autoscroll or true

  --- number, purge lines when total is higher than this
  self.max_lines = 50

  -- initialize --

	vCompositeControl.__init(self,...)
  local vb = self.vb

  self.view = vb:multiline_textfield{
    id = self.id,
    font = "mono",
  }

  -- views --

  self.clear_button = vb:button{
    text = "Clear",
    notifier = function()
      self:clear()
    end,
  }

  self:register_views(vLogView.VIEWS)

  self.width = args.width or vLogView.DEFAULT_H
  self.height = args.height or vLogView.DEFAULT_W

  if args.text then
    self:set_text(args.text)
  end

end



--------------------------------------------------------------------------------
--- clear all text in log

function vLogView:clear()

  self.view.text = ""

end

--------------------------------------------------------------------------------
--- clear text to log (strip leading, trailing whitespace)
-- @param txt (string)

function vLogView:add(txt)

  txt = cString.strip_leading_trailing_chars(tostring(txt),"\n",true,true)

  if (self.view.text == nil) or (self.view.text == "") then
    self.view.text = txt
  else
    local paras = self.view.paragraphs
    table.insert(paras,txt) 
    if (self.max_lines > 0) 
      and (#paras > self.max_lines) 
    then
      -- purge some paragraphs
      while(#paras > self.max_lines) do
        table.remove(paras,1)
      end
    end
    self.view.paragraphs = paras
  end

  if self.autoscroll then
    self.view:scroll_to_last_line()
  end

end

--------------------------------------------------------------------------------
--- replace the last line in the log
-- @param txt (string)

function vLogView:replace(txt)

  txt = cString.strip_leading_trailing_chars(txt,"\n",true,true)
  local paras = self.view.paragraphs
  paras[#paras] = txt
  self.view.paragraphs = paras
  if self.autoscroll then
    self.view:scroll_to_last_line()
  end

end

--------------------------------------------------------------------------------

function vLogView:set_text(str)
  self:clear()
  self:add(str)
end

function vLogView:get_text()
  return self.view.text
end

--------------------------------------------------------------------------------
--[[
function vLogView:set_active(val)
  self.view.active = val
  vControl.set_active(self,val)
end

function vLogView:get_active()
  return self.view.active
end
]]
