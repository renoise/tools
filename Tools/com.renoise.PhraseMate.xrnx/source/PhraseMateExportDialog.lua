--[[============================================================================
-- PhraseMateExportDialog
============================================================================]]--

--[[--

PhraseMate (user-interface)

--]]


--==============================================================================

class 'PhraseMateExportDialog' (vDialog)

function PhraseMateExportDialog:__init(...)
  TRACE("PhraseMateExportDialog:__init(...)")

  self.prefs = renoise.tool().preferences
  vDialog.__init(self,...)

  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="PhraseMate")

  --- PhraseMate
  self.owner = args.owner

  -- internal -------------------------

  --- vPathSelector
  self.vpathselector = nil

  --- vTable
  self.vtable = nil

end

--------------------------------------------------------------------------------

function PhraseMateExportDialog:create_dialog()
  TRACE("PhraseMateExportDialog:create_dialog()")

  local vb = self.vb

  local dialog_w = 250
  local label_w = 40

  self.vtable = vTable{
    id = "vTable",
    vb = vb,
    width = dialog_w,
    row_height = 19,
    num_rows = 10,
    cell_style = "group",
    show_header = false,
    column_defs = {
      {
        key = "CHECKED",
        col_width = 20, 
        col_type = vTable.CELLTYPE.CHECKBOX,
        notifier = function(elm,checked)
          local item = elm.owner:get_item_by_id(elm.item_id)
          if item then
            item.CHECKED = checked
          end
        end
      },
      {
        key = "INDEX",
        col_width = 20,
        col_type = vTable.CELLTYPE.TEXT,
      },
      {
        key = "NAME",
        col_type = vTable.CELLTYPE.TEXTFIELD,
        col_width = "auto",
        notifier = function(elm,val)
          local item = elm.owner:get_item_by_id(elm.item_id)
          if item then
          end
        end
      }
    },
    header_defs = {
      CHECKED = {
        data = true,
        col_type = vTable.CELLTYPE.CHECKBOX, 
        active = true, 
        notifier = function(elm,checked)
          --self.vtable.header_defs.CHECKED.data = checked
          for k,v in ipairs(self.vtable.data) do
            v.CHECKED = checked
          end
          self.vtable:request_update()
        end
      },
      INDEX = {
        data = "#",
      },
      NAME = {
        data = "Name",
      },
    },
    data = {}
  }

  self.vb_output_folder = vb:text{
    text = "",
    font = "italic",
  }

  return vb:column{
    margin = PhraseMateUI.UI_MARGIN,
    spacing = PhraseMateUI.UI_SPACING,
    vb:column{
      margin = PhraseMateUI.UI_MARGIN*2,
      style = "group",
      self.vb_output_folder,
    },
    vb:column{
      style = "group",
      self.vtable.view,
    },
    vb:button{
      width = dialog_w,
      height = PhraseMateUI.BUTTON_SIZE,
      text = "Export selected phrases",
      notifier = function()
        local rslt,err = self:submit()
        if err then
          renoise.app():show_warning(err)
        end
      end
    },
  }

end

--------------------------------------------------------------------------------

function PhraseMateExportDialog:update()
  TRACE("PhraseMateExportDialog:update()")

  local data = self.owner.ui:get_vtable_phrase_data()

  for k,v in ipairs(data) do
    v.INDEX = ("%.2X"):format(k)
  end

  self.vtable.data = data

  local msg = "The phrases will be exported to this location: \n%s"
  local output_folder = self.prefs.output_folder.value
  self.vb_output_folder.text = msg:format(output_folder)

end

--------------------------------------------------------------------------------

function PhraseMateExportDialog:show()
  TRACE("PhraseMateExportDialog:show()")

  vDialog.show(self)
  self:update()

end

--------------------------------------------------------------------------------
-- validate before submitting
-- @return bool, true when able to submit

function PhraseMateExportDialog:submit()
  TRACE("PhraseMateExportDialog:submit()")

  local indices = {}
  for k,v in ipairs(self.vtable.data) do
    if (v.CHECKED) then
      table.insert(indices,k)
    end
  end

  self.owner.ui:export_presets(indices)

  return true

end
