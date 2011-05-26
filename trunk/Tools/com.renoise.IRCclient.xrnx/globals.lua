--[[============================================================================
globals.lua
============================================================================]]--

sirc_debug = false

DISCONNECTED = 0
IN_PROGRESS = 1
CONNECTED = 2

irc_host = "canis.esper.net"
irc_port = 6667
irc_user = "guest"
irc_nick_name = "jdoe452"
--local irc_real_name = "Renoise IRC client"
irc_real_name = "http://tools.renoise.com"
irc_channel = "#renoise"
socket_timeout = 1000
client, client_error = nil
rirc = nil
last_idle_time = 0
irc_dialog = nil
chat_dialog = nil
login_dialog = nil
connect_progress_dialog = nil
session = {}
sessions = 1
target = nil
vb_channel = nil
no_loop = 0 --Prevent (empty) chat text from being send after striking just one key
vb_status = nil
vb_login = nil
active_channel = nil
quit_reply = nil
status_dialog_mode = false
switch_channel = true
chat_hidden = false
connection_status = DISCONNECTED
chat_buffer = ''

channel_users = {}

known_commands = {
 "join", "part", "nick", "list", "names", "topic", "invite", "stats",
 "kick", "links", "time", "trace", "connect", "admin", "info", "who",
 "whois", "whowas", "notice", "version", "quit", "oper", "mode", "privmsg"
}


--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

string.split = function(str, pattern)
  pattern = pattern or "[^%s]+"
  if pattern:len() == 0 then pattern = "[^%s]+" end

  local parts = {__index = table.insert}
  setmetatable(parts, parts)
  str:gsub(pattern, parts)
  setmetatable(parts, nil)
  parts.__index = nil

  return parts
end

