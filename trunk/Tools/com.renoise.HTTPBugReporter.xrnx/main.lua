-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "renoise.http"


-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

local entry = {}
entry.name = "Main Menu:Help:Report a Bug..."
entry.invoke = function() start() end
renoise.tool():add_menu_entry(entry)


-------------------------------------------------------------------------------
--  Document
-------------------------------------------------------------------------------

local bug_report = renoise.Document.create {
  topic = "",
  summary = "what happened?",
  description = {"please describe the problem as detailed as possible here"},
  email = "your email",
  name = "your name" ,
  severe = false,
  add_log = false,
  log = "",
}


-------------------------------------------------------------------------------
--  Processing
-------------------------------------------------------------------------------

function submit(callback)
  local my_callback = callback or function(data) rprint(data) end
  
  local description = table.create()
  for i=1,#bug_report.description do
    description:insert(bug_report.description[i].value)
  end
  
  local settings = table.create()
  settings.url = "http://www.renoise.com/bugs/index.php"
  settings.method = "post"
  settings.data = { 
    action = "submit", 
    topic = bug_report.topic.value, 
    summary = bug_report.summary.value, 
    description = description, 
    severe = bug_report.severe.value,
    email = bug_report.email.value,
    name = bug_report.name.value
  }
  settings.data_type = "json"  
  settings.success = function( result, status, xhr )
    if (result.status == "OK") then      
      show_confirmation()        
    else
      show_error()
    end
  end
  --settings.content_type = "multipart/form-data"   
  
  Request(settings)
end


-------------------------------------------------------------------------------
--  Gui
-------------------------------------------------------------------------------

local dialog = nil


-- show_confirmation

function show_confirmation()
  renoise.app():show_prompt(
    "Report Submited",
    "Your bug report has been received. Thanks!", 
    {"OK"}
  )
  
  dialog:close()
end


-- show_error

function show_error()
  renoise.app():show_error(
    "Error while sending your bug report. How ironic!")

  dialog:close()
end


-- start

function start()
  if (dialog and dialog.visible) then
    dialog:show()
    return
  end

  local vb = renoise.ViewBuilder()
  
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN  
  local DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local DEFAULT_DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  
  local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

  local topic_group = vb:column {
    style = "group",
    margin = DEFAULT_MARGIN,      
    spacing = DEFAULT_SPACING,
    uniform = true,  
      
    vb:text {
      text = "I think this bug is related to:",
      font = "bold"
    },

    vb:row {
      width = "100%",
      
      vb:popup {
        width = 120,
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
          "Something else..."
        },
        notifier = function(value) 
          local last = #vb.views.topic_popup.items
          vb.views.other_topic_text.visible = (value == last)
          vb.views.other_topic_textfield.visible = (value == last)

          if (value == last) then
            bug_report.topic.value = vb.views.other_topic_textfield.text
          else
            bug_report.topic.value = vb.views.topic_popup.items[value]
          end
        end        
      },
    
      vb:space { width = DEFAULT_SPACING},
      
      vb:text {
        id = "other_topic_text",
        text = "namely:",
        visible = false,                
      },
      
      vb:textfield {
        id = "other_topic_textfield",
        visible = false,
        width = 116,        
      }
    }
  }  
  
  local form_group = vb:column {  
    id = "form_group",
    style = "group",
    margin = DEFAULT_MARGIN,      
    spacing = DEFAULT_SPACING,
    uniform = true,
    
    vb:text {
       font = "bold",
       text = "Summary:"
    },
    vb:textfield {
      bind = bug_report.summary
    },        
       
    vb:space { height = DEFAULT_SPACING},
    
    vb:text {
       font = "bold",
       text = "Description:"
    },
    vb:multiline_textfield {
       bind = bug_report.description,
       height = 80
    },      
    
    vb:row {       
      vb:checkbox {
        bind = bug_report.severe
      },  
      vb:text {
        text = "Renoise crashed or the system became unresponsive."
      },
    },
  }  
    
  local optional_group = vb:column {
    id = "optional_group",
    style = "group",
    margin = DEFAULT_MARGIN,      
    spacing = DEFAULT_SPACING,

    vb:horizontal_aligner {
      mode = "justify",
      
      vb:row {
        vb:checkbox {
          bind = bug_report.add_log
        },
        vb:text {
          text = "Include log with bug report"
        },
      },
      
      vb:button {
        text = "Read log",
        notifier = function() 
          -- TODO
        end
      },        
    },
    
    vb:row {
    
      vb:checkbox {
        id = "subscribe_checkbox",
        notifier = function(value)
          vb.views.subscribe_column.visible = value
          vb.views.optional_group:resize()
          vb.views.dialog_content:resize()
        end
      },
      
      vb:text {
        text = "Keep me up-to-date about this bug"        
      },    
    },
    
    vb:column {
      id = "subscribe_column",
      visible = false,

      vb:textfield {
        bind = bug_report.name,
        width = 150,
      },
        
      vb:textfield {
        bind = bug_report.email,
        width = 150,
      }
    }
  }  
  
  local form = vb:column {
    margin = DEFAULT_MARGIN,      
    spacing = DEFAULT_DIALOG_SPACING,
    uniform = true, 
    
    vb:text {
      text = "To submit a bug report, please fill in this form." 
    },
    
    topic_group,
    form_group, 
    optional_group
  }
  
  local dialog_content = vb:column {
    id = "dialog_content",
    margin = DEFAULT_MARGIN,
    width = 200,
      
    form,

    vb:horizontal_aligner {
      mode = "center",
      margin = DEFAULT_MARGIN,
  
      vb:button {
        text = "Submit",
        height = DIALOG_BUTTON_HEIGHT,
        notifier = function() 
          submit()
        end
      }, 
    }
  }

  dialog = renoise.app():show_custom_dialog(
    "Bug Reporter", dialog_content)
  
end
