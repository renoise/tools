--[[===============================================================================================
vLibBoilerPlate
===============================================================================================]]--

--[[

User interface for vLibBoilerPlate. Extends the vDialog class, which provides
methods for launching the window automatically on startup

]]

--=================================================================================================

class 'vLibBoilerPlate_UI' (vDialog)

---------------------------------------------------------------------------------------------------
-- Constructor method

function vLibBoilerPlate_UI:__init(...)

  -- when extending a class, it's constructor needs to be called
  -- we also pass the arguments (...) along to the vDialog constructor 
  vDialog.__init(self,...)

  self.vb = renoise.ViewBuilder()

  self:build()

end

---------------------------------------------------------------------------------------------------
-- Build the UI (executed once)

function vLibBoilerPlate_UI:build()
  TRACE("vLibBoilerPlate_UI:build()")
  
  local vb = self.vb
  local vb_content = vb:row{
    vb:row{
      vb:checkbox{
        bind = renoise.tool().preferences.autostart
      },
      vb:text{
        text = "autostart"
      }
    }
  }

  self.vb_content = vb_content

end

---------------------------------------------------------------------------------------------------
-- methods required by vDialog
---------------------------------------------------------------------------------------------------
-- return the UI which was previously created with build()

function vLibBoilerPlate_UI:create_dialog()
  TRACE("vLibBoilerPlate_UI:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

