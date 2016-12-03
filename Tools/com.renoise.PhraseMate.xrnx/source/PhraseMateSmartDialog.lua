--[[============================================================================
-- PhraseMateSmartDialog
============================================================================]]--

--[[--

PhraseMate (user-interface)

--]]


--==============================================================================

class 'PhraseMateSmartDialog' (vDialog)

function PhraseMateSmartDialog:__init(...)
  TRACE("PhraseMateSmartDialog:__init(...)")

  self.prefs = renoise.tool().preferences
  vDialog.__init(self,...)

  local args = cLib.unpack_args(...)

  --- PhraseMate
  self.owner = args.owner

  -- internal -------------------------

  --- boolean
  self._suppress_notifier = false

  --- vSearchField
  self.searchfield = nil

  --- bool
  self.update_requested = false

  --- table
  --  {
  --    folder = string, --  full path
  --    filename = string, --  filename
  --    name = string,  --  "search name" (without prefix, extension)
  --  }

  self.exported_phrases = nil

  self.dialog_keyhandler = function(vdlg,dlg,key)


    local handled = false

    if not key.repeated and (key.modifiers == "") then
      local switch = {
        ["tab"] = function()
          self.searchfield.edit_mode = true
        end,
        ["return"] = function()
          self:apply()
        end,
        ["esc"] = function()
          self.dialog:close()
        end,
      }
      if switch[key.name] then
        switch[key.name]()
        handled = true
      end
    end

    if not handled then
      return key
    end

  end
  

  -- notifiers --

  --[[
  self.prefs.use_custom_note:add_notifier(function()
    self:update_note()
  end)

  self.prefs.custom_note:add_notifier(function()
    self:update_note()
  end)
  ]]

  self.prefs.use_exported_phrases:add_notifier(function()
    self.searchfield.text = ""
    self:update_searchfield()
  end)

  renoise.tool().app_new_document_observable:add_notifier(function()
    self:attach_to_song()
  end)

  renoise.tool().app_idle_observable:add_notifier(function()
    if self.update_requested then
      self.update_requested = false
      self:update()
    end
  end)

  self:attach_to_song()

  --self:update()


end

--------------------------------------------------------------------------------

function PhraseMateSmartDialog:create_dialog()
  TRACE("PhraseMateSmartDialog:create_dialog()")

  local vb = self.vb

  local UI_WIDTH = 300
  local UI_LABEL_W = 40
  local UI_BUTTON_W = 90
  local UI_POPUP_W = UI_WIDTH - (UI_LABEL_W+UI_BUTTON_W)

  self.searchfield = vSearchField{
    vb = vb,
    width = UI_WIDTH,
    height = 20,
    popup = true,
  }
  self.searchfield.selected_index_observable:add_notifier(function()
    self:update()
  end)

  return vb:column{
    margin = PhraseMateUI.UI_MARGIN,
    vb:column{
      style = "group",
      margin = PhraseMateUI.UI_MARGIN,
      vb:space{
        width = UI_WIDTH,
        height = 1,
      },
      vb:row{
        margin = 2,
        self.searchfield.view,
      },
      vb:row{
        vb:row{
          margin = 2,
          --[[ TODO
          vb:column{
            margin = 2,
            vb:row{ -- note
              vb:text{
                width = UI_LABEL_W,
                text = "Note",
              },
              vb:checkbox{
                id = "ui_note_cb",
                tooltip = "Determine phrase note:"
                      .."\nChecked   = custom (specify via valuebox)"
                      .."\nUnchecked = automatic (use phrase base-note)",
                --bind = self.prefs.use_custom_note,
                notifier = function(val)
                  self:update_note()
                end
              },
              vb:valuebox{
                width = UI_WIDTH/3-UI_LABEL_W,
                id = "ui_note",
                tonumber = function(val)
                  return xNoteColumn.note_string_to_value(val)
                end,
                tostring = function(val)
                  return xNoteColumn.note_value_to_string(val)
                end,
                notifier = function(val)
                  --self.prefs.custom_note.value = val
                  self:update_note()
                end
              },
            },
            vb:row{ -- scale
              vb:text{
                width = UI_LABEL_W,
                text = "Scale",
              },
              vb:checkbox{
                tooltip = "(TODO) Restrict to scale",
                active = false,
                notifier = function()
                  
                end
              },
              vb:popup{
                id = "ui_select_scale_key",
                active = false,
                width = UI_WIDTH/3-UI_LABEL_W,
                items = xScale.SCALE_NAMES,
              },
            },
          },
          ]]
          vb:column{
            margin = 2,
            vb:row{
              vb:text{
                text = "Source",
                width = UI_LABEL_W,
              },
              vb:popup{
                id = "ui_output_src",
                width = UI_POPUP_W,
                items = {
                  "Use instrument phrases",
                  "Use exported phrases (.xrnz)",
                },
                value = self.prefs.use_exported_phrases.value 
                  and PhraseMate.OUTPUT_SOURCE.PRESET
                  or PhraseMate.OUTPUT_SOURCE.SELECTED,
                notifier = function(idx)
                  self.prefs.use_exported_phrases.value = 
                    (idx == PhraseMate.OUTPUT_SOURCE.PRESET) and true or false
                end
              },
            },
            vb:row{
              vb:text{
                text = "Mode",
                width = UI_LABEL_W,
              },
              vb:popup{
                id = "ui_output_mode",
                width = UI_POPUP_W,
                items = {
                  "Write to selection",
                  "Write to track",
                },
              },
            },
          },
          vb:button{
            id = "ui_output",
            text = "Write [Return]",
            width = UI_BUTTON_W,
            height = 40,
            notifier = function()
              self:apply()
            end
          },

        },
      },
      --[[
      vb:text{
        text = "NB: using current write settings, stored phrases "
            .."\nare loaded from the 'Import' path",
        font = "italic",
      }
      ]]
    },

  }
  
end

--------------------------------------------------------------------------------

function PhraseMateSmartDialog:update()
  TRACE("PhraseMateSmartDialog:update()")

  self:update_searchfield()
  self:update_apply_button()

end

--------------------------------------------------------------------------------
-- when importing, obtain path, filename and the "raw" searchable name

function PhraseMateSmartDialog:get_exported_phrases()
  TRACE("PhraseMateSmartDialog:get_exported_phrases()")

  local folder = self.prefs.output_folder.value
  local files = {}
  local handler = function(folder,filename,filetype)
    if (filetype == cFilesystem.FILETYPE.FILE) then
      table.insert(files,{
        folder = folder,
        filename = filename,
        name = xPhrase.get_raw_preset_name(filename)
      })
    end
    return true
  end

  cFilesystem.recurse(folder,handler,{"*.xrnz"})

  self.exported_phrases = files

end

--------------------------------------------------------------------------------

function PhraseMateSmartDialog:update_searchfield()
  TRACE("PhraseMateSmartDialog:update_searchfield()")

  local vb = self.vb

  local phrase_list = PhraseMateUI.get_phrase_list(nil,nil,false)

  local use_exported = self.prefs.use_exported_phrases.value
  vb.views["ui_output_src"].value = use_exported 
    and PhraseMate.OUTPUT_SOURCE.PRESET 
    or PhraseMate.OUTPUT_SOURCE.SELECTED

  if use_exported then
    self.searchfield.items = cLib.match_table_key(self.exported_phrases,"name")
  else
    self.searchfield.items = phrase_list
  end

  if table.is_empty(self.searchfield.items) then
    self.searchfield.placeholder = "No phrases available"  
    self.searchfield.active = false
  else
    self.searchfield.placeholder = "Enter name of phrase..."  
    self.searchfield.active = true
  end 

end

--------------------------------------------------------------------------------

function PhraseMateSmartDialog:update_apply_button()
  TRACE("PhraseMateSmartDialog:update_apply_button()")

  local vb = self.vb
  if (self.searchfield.selected_index > 0) then
    vb.views["ui_output"].active = true
  else
    vb.views["ui_output"].active = false
  end

end

--------------------------------------------------------------------------------
--[[
function PhraseMateSmartDialog:update_note()
  TRACE("PhraseMateSmartDialog:update_note()")

  local vb = self.vb
  local custom_checked = vb.views["ui_note_cb"].value
  local selected_note = rns.selected_phrase
    and rns.selected_phrase.base_note or 48

  local note = nil
  if self.prefs.use_custom_note.value then
    note = self.prefs.custom_note.value
  else
    note = selected_note
  end

  vb.views["ui_note"].active = custom_checked
  vb.views["ui_note"].value = note

end
]]
--------------------------------------------------------------------------------

function PhraseMateSmartDialog:show()
  TRACE("PhraseMateSmartDialog:show()")

  vDialog.show(self)

  self:get_exported_phrases()
  self:update()

  self.searchfield.edit_mode = true

end

--------------------------------------------------------------------------------

function PhraseMateSmartDialog:attach_to_song()
  TRACE("PhraseMateSmartDialog:attach_to_song()")

  local schedule_update = function ()
    self.update_requested = true
  end

  cObservable.attach(rns.selected_phrase_observable,schedule_update)
  cObservable.attach(rns.selected_instrument_observable,function()
    local instr = rns.selected_instrument
    cObservable.attach(instr.phrases_observable,schedule_update,self)
  end)
  cObservable.attach(rns.instruments_observable,schedule_update)

end

--------------------------------------------------------------------------------

function PhraseMateSmartDialog:apply()
  TRACE("PhraseMateSmartDialog:apply()")

  local vb = self.vb

  if (self.searchfield.selected_index == 0) then
    return 
  end

  local source = vb.views["ui_output_src"].value
  local mode = vb.views["ui_output_mode"].value
  local rslt,err

  if (source == PhraseMate.OUTPUT_SOURCE.SELECTED) then
    local cached_phrase_idx = rns.selected_phrase_index
    rns.selected_phrase_index = self.searchfield.selected_index
    if (mode == PhraseMate.OUTPUT_MODE.SELECTION) then
      rslt,err = self.owner:apply_to_selection()
    elseif (mode == PhraseMate.OUTPUT_MODE.TRACK) then
      rslt,err = self.owner:apply_to_track()
    else
      error("Unexpected mode")
    end
    rns.selected_phrase_index = cached_phrase_idx
  elseif (source == PhraseMate.OUTPUT_SOURCE.PRESET) then
    local export = self.exported_phrases[self.searchfield.selected_index]
    local fpath = export.folder .. "/" .. export.filename
    rslt,err = self.owner:apply_external_phrase(mode,fpath)
  end

  if not rslt then
    renoise.app():show_warning(tostring(err))
  end

end


