-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "renoise.http"


-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

local entry = {}

entry.name = "Main Menu:Tools:Report A Bug..."
entry.active = function() return true end
entry.invoke = function() start() end
renoise.tool():add_menu_entry(entry)


-------------------------------------------------------------------------------
--  Main functions
-------------------------------------------------------------------------------

local vb = nil
local dialog = nil

local function show_confirmation()
  vb.views.confirmation.visible = true
  vb.views.confirmation.text = "Your bug report has been received. Thanks!"
end

local function show_error()
  vb.views.confirmation.visible = true
  vb.views.confirmation.text = "Error while sending your bug report. How ironic!"
end

local function submit(callback)
  local my_callback = callback or function(data) rprint(data) end
  
  local topic = vb.views.topic_popup.items[vb.views.topic_popup.value]
  if (topic == "") then
    topic = vb.views.other_topic_textfield.text
  end
  local summary = vb.views.summary_textfield.text
  local description = vb.views.description_textfield.text
  local email = vb.views.email_textfield.text
  local severe = vb.views.severe_checkbox.value
  local log = ""

  HTTP:post("http://www.renoise.com/bugs/index.php",
    { 
      action="submit", 
      topic=topic, 
      summary=summary, 
      description=description, 
      severe=severe,
      email=email      
    },
    function( result, status, xhr )
      if (result.status == "OK") then      
        show_confirmation()
        rprint(result.formdata)
      else
        show_error()
      end
    end, "json")
end

function start()
  
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  vb = renoise.ViewBuilder()
  
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN  
  local DEFAULT_SPACING = 5
  
  local topic_group = vb:column {
    style = "group",
    margin = DEFAULT_MARGIN,      
    spacing = DEFAULT_SPACING,
    
    vb:row {
      spacing = DEFAULT_SPACING,
      
      vb:text {
        text = "I think this bug is related to"
      },           
      
      vb:popup {
        id = "topic_popup",
        items = { 
          "",
          "Audio",
          "Pattern Matrix",
          "Pattern Editor",
          "Mixer",
          "Sample Editor",
          "Instrument Editor",
          "Track DSP",
          "Automation Editor",
          "Disk Browser",
          "GUI",
          "Rendering",
          "File I/O",
          "Plugin",
          "Scripts", 
          "Something Else..."
        },
        notifier = function(value) 
          local item = vb.views.topic_popup.items[value]          
          vb.views.other_topic_text.visible = (item =="Something Else...")
          vb.views.other_topic_textfield.visible = (item =="Something Else...")
        end        
      }
    },
    
    vb:text {
      id = "other_topic_text",
      text = "Namely:",
      visible = false
    },
    
    vb:textfield {
      id = "other_topic_textfield",
      visible = false
    },
  }  
  
  local form_group = vb:column {      
    style = "group",
    margin = DEFAULT_MARGIN,      
    spacing = DEFAULT_SPACING,
    uniform = true,
    
    vb:text {
       font = "bold",
       text = "Summary:"
    },

    vb:textfield {
      id = "summary_textfield"
    },           

    vb:text {
       font = "bold",
       text = "Description (textbox):"
    },

    vb:textfield {
       id = "description_textfield",
    },      
    
    vb:row {       
      spacing = DEFAULT_SPACING,
      
      vb:checkbox {
        id = "severe_checkbox",
        value = false
      },  
      
      vb:text {
        text  = "Renoise crashed or the system became unresponsive."
      },
          
    },
  }  
    
  local optional_group = vb:column {
      style = "group",
      margin = DEFAULT_MARGIN,      
      spacing = DEFAULT_SPACING,
      uniform = true,

    vb:row {
      spacing = DEFAULT_SPACING,    
      
      vb:checkbox {
        id = "add_log_checkbox",
        value = true
      },
      
      vb:text {
        text = "Include log with bug report"
      },
      
      vb:button {
        text = "Read log",
        notifier = function() 
        end
      },        
    },
    
    vb:text {
      text = "(Optional) Keep me up-to-date on this e-mail address:"        
    },
      
    vb:textfield {
      id = "email_textfield",         
    }
  }  
  
  local form = vb:column {
      margin = DEFAULT_MARGIN,      
      spacing = DEFAULT_SPACING,
      uniform = true, 
      
    vb:row {
      margin = DEFAULT_MARGIN,            

      vb:text {
        text = "To submit a bug report, please fill in this form."
      },
    },
    
    topic_group,
    
    form_group, 
    
    optional_group
  }
  
  local dialog_content = vb:horizontal_aligner {
    mode = "center",
    width = 200,
    vb:column {
      vb:row { 
        style = "body",
        margin = 5,
        spacing = 5,
        form 
      },
      vb:row {
        margin = 5,
        spacing = 5,
        vb:button {
          text = "Submit",
          notifier = function() 
            submit()
          end
        }, 
        vb:text {
          id = "confirmation",
          visible = false          
        }
      }
    }
  }

  dialog = renoise.app():show_custom_dialog("Bug Reporter",
    dialog_content);
  
end
