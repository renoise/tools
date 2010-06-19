------------------------------------------------------------------------------
----------------------        Globals for IRC        -------------------------
------------------------------------------------------------------------------


irc_host = "canis.esper.net"
irc_port = 6667
irc_user = "guest"
irc_nick_name = "jdoe452"
--local irc_real_name = "Renoise IRC client"
irc_real_name = "J. dorkalong"
irc_channel = "#myhhchannel"
socket_timeout = 1000
client, client_error = nil
rirc = nil
last_idle_time = 0
irc_dialog = nil
chat_dialog = nil
session = {}
sessions = 1
target = nil
vb_channel = nil
vb_status = nil
sirc_debug = false
active_channel = nil

channel_users = {}

known_commands = {
 "join", "part", "nick", "list", "names", "topic", "invite", "stats",
 "kick", "links", "time", "trace", "connect", "admin", "info", "who",
 "whois", "whowas", "notice", "version", "quit", "oper", "mode"
}

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
