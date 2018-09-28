class 'AppUIAbout' (vDialog)

AppUIAbout.DIALOG_W = 400
AppUIAbout.TXT_ABOUT = [[This tool adds basic Sononym integration to Renoise. Use it to: 
• Search for similar samples (Renoise → Sononym)
• Transfer samples from Sononym → Renoise 
• Replace samples in Renoise while browsing in Sononym (auto-transfer)

NB: LAUNCH SONONYM *BEFORE* USING SEARCH  
The tool will require Sononym to be running before launching a search - 
otherwise the Sononym process might lock Renoise. If you do this by 
accident, simply close the Sononym window and start Sononym 
from its usual place (Start Menu, Dock, etc).

]]

---------------------------------------------------------------------------------------------------

function AppUIAbout:__init(...) 
  TRACE("AppUIAbout:__init")

  vDialog.__init(self,...)
  
  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="App","Expected 'owner' to be an instance of App")

  local vb = self.vb
  
  self.dialog_content = vb:column{
    margin = 20,
    spacing = 10,
    width = AppUIAbout.DIALOG_W,
    vb:bitmap{
      bitmap = "source/icons/logo.png",
    },
    vb:text{
      text = "ABOUT",
      font = "big",
    },
    vb:text{
      text = AppUIAbout.TXT_ABOUT
    },    
    vb:horizontal_aligner{
      mode = "justify",
      vb:text{
        text = "Version: "..args.owner.tool_version
      },
      vb:button{
        text = "Full Documentation"
      }
    },

  }
  
end
