--------------------------------------------------------------------------------
-- Variables & Globals, captialized for easier recognition
--------------------------------------------------------------------------------

-- @see: http://soundcloud.com/you/apps/renoise/edit

local CLIENT_ID = 'f30ef59aa56e4f03af9f766e224cfca5'
local CLIENT_SECRET = '2665038241b6a839126d9d90ab0a1810'
local REDIRECT_URI = 'http://connect.soundcloud.com/desktop'

--------------------------------------------------------------------------------
-- Fix executable permissions
--------------------------------------------------------------------------------

if os.platform() == 'MACINTOSH' then
  io.chmod(renoise.tool().bundle_path .. 'bin/osx/Share on SoundCloud.app/Contents/MacOS/Share on SoundCloud', 755);
end

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Escapes string, so it does not contain any symbols, potentially harmful to the shell.
local function escape(...)
 local command = type(...) == 'table' and ... or { ... }
 for i, s in ipairs(command) do
  s = (tostring(s) or ''):gsub('"', '\\"')
  if s:find '[^A-Za-z0-9_."/-]' then
   s = '"' .. s .. '"'
  elseif s == '' then
   s = '""'
  end
  command[i] = s
 end
 return table.concat(command, ' ')
end


-- Share on SoundCloud
function launch_soundcloud_app(filename)
  local cmd
  local path_to_soundcloud_app
  if os.platform() == 'WINDOWS' then
    -- Windows
    -- @see: https://github.com/soundcloud/soundcloud-win-sharing

    path_to_soundcloud_app = renoise.tool().bundle_path .. "bin/win/Share on SoundCloud.exe"
    if not io.exists(path_to_soundcloud_app) then
      renoise.app():show_message("Error: Cannot find Share on SoundCloud.exe")
      print("Something is wrong with the following path:")
      print(path_to_soundcloud_app)
      return
    end

    cmd = string.format(
      'start "SoundCloud App" "%s" "%s" /client_id:%s /client_secret:%s /redirect_uri:%s /track[title]:%s',
       path_to_soundcloud_app,
       filename,
       CLIENT_ID,
       CLIENT_SECRET,
       REDIRECT_URI,
       escape(renoise.song().name)
    )
  elseif os.platform() == 'MACINTOSH' then
    -- Macintosh
    -- @see: https://github.com/soundcloud/soundcloud-mac-sharing

    path_to_soundcloud_app = renoise.tool().bundle_path .. "bin/osx/Share on SoundCloud.app"
    if not io.exists(path_to_soundcloud_app) then
      renoise.app():show_message("Error: Cannot find Share on SoundCloud.app")
      print("Something is wrong with the following path:")
      print(path_to_soundcloud_app)
      return
    end

    cmd = string.format(
      '/usr/bin/open "%s" --new --args -client_id %s -client_secret %s -redirect_uri %s -track\[title\] %s -track\[asset_data\] %s',
       path_to_soundcloud_app,
       CLIENT_ID,
       CLIENT_SECRET,
       REDIRECT_URI,
       escape(renoise.song().name),
       filename
    )

  else
    -- Error, unsuporterd platform
    renoise.app():show_message(
    "Sorry, this Tool works only with Windows or Macintosh."
    )
    return
  end

  local error_msg = os.execute(cmd)
  if error_msg ~= 0 then
    renoise.app():show_message(
      string.format("Error %i: Something went wrong. Could not start 'Share on SoundCloud'.", error_msg)
    )
    print("Something went wrong with the following command:")
    print(cmd)
  end
end


-- Render function
function render_to_soundcloud()
  renoise.song().transport.follow_player = true
  renoise.app().window.active_middle_frame = renoise.ApplicationWindow.MIDDLE_FRAME_PATTERN_EDITOR

  local filename = os.tmpname('wav')
  renoise.song():render(filename, function() launch_soundcloud_app(filename) end )
end


--------------------------------------------------------------------------------
-- Menu Registration, Key Bindings
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:File:Render Song to SoundCloud...",
  invoke = render_to_soundcloud
}
