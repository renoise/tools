if (os.platform() == "LINUX") then
  -- As simple as this:
  os.execute('pulseaudio -k')
end
