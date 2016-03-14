--[[============================================================================
-- xRulesAppPrefs
============================================================================]]--

--[[

  This is a supporting class for xRulesApp

]]

--==============================================================================

class 'xRulesAppPrefs'(renoise.Document.DocumentNode)

-- general 
xRulesAppPrefs.AUTORUN_ENABLED = true
xRulesAppPrefs.SHOW_ON_STARTUP = true
xRulesAppPrefs.SHOW_MINIMIZED = false
xRulesAppPrefs.RULESET_FOLDER = renoise.tool().bundle_path .. "/rulesets/"

-- midi options
xRulesAppPrefs.MULTIBYTE_ENABLED = true
xRulesAppPrefs.NRPN_ENABLED = true
xRulesAppPrefs.TERMINATE_NRPNS = false

-- osc options
xRulesAppPrefs.OSC_CLIENT_HOST = "127.0.0.1"
xRulesAppPrefs.OSC_CLIENT_PORT = 8000


function xRulesAppPrefs:__init()

  renoise.Document.DocumentNode.__init(self)

  self:add_property("autorun_enabled", renoise.Document.ObservableBoolean(xRulesAppPrefs.AUTORUN_ENABLED))
  self:add_property("show_on_startup", renoise.Document.ObservableBoolean(xRulesAppPrefs.SHOW_ON_STARTUP))
  self:add_property("show_minimized", renoise.Document.ObservableBoolean(xRulesAppPrefs.SHOW_MINIMIZED))
  self:add_property("ruleset_folder", renoise.Document.ObservableString(xRulesAppPrefs.RULESET_FOLDER))

  self:add_property("midi_multibyte_enabled", renoise.Document.ObservableBoolean(xRulesAppPrefs.AUTORUN_ENABLED))
  self:add_property("midi_nrpn_enabled", renoise.Document.ObservableBoolean(xRulesAppPrefs.NRPN_ENABLED))
  self:add_property("midi_terminate_nrpns", renoise.Document.ObservableBoolean(xRulesAppPrefs.TERMINATE_NRPNS))

  self:add_property("osc_client_host", renoise.Document.ObservableString(xRulesAppPrefs.OSC_CLIENT_HOST))
  self:add_property("osc_client_port", renoise.Document.ObservableNumber(xRulesAppPrefs.OSC_CLIENT_PORT))

  self:add_property("active_rulesets", renoise.Document.ObservableStringList())

  self:add_property("midi_inputs", renoise.Document.ObservableStringList())
  self:add_property("midi_outputs", renoise.Document.ObservableStringList())
  --print("xRulesAppPrefs:__init - #midi_inputs",#self.midi_inputs)
  --print("xRulesAppPrefs:__init - #midi_outputs",#self.midi_outputs)

  --self:add_property("osc_devices",renoise.Document.create("OscDevices"){})
  --print("xRulesAppPrefs:__init - osc_devices",self.osc_devices)

  self:add_property("osc_devices", renoise.Document.ObservableStringList())
  --print("xRulesAppPrefs:__init - #osc_devices",#self.osc_devices)

  self:property("ruleset_folder"):add_notifier(function()
    self:property("ruleset_folder").value = xFilesystem.unixslashes(self:property("ruleset_folder").value)
  end)


end

