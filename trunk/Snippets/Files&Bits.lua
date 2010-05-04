-[[----------------------------------------------------------------------------
-- Files & Bits
---------------------------------------------------------------------------]]--

error("do not run this file. read and copy/paste from it only...")


-- reading integer numbers or raw bytes from a file

local function read_word(file)
  local bytes = file:read(2)
  if (not bytes or #bytes < 2) then 
    return nil 
  else
    return bit.bor(bytes:byte( 1),
      bit.lshift(bytes:byte(2), 8))
  end
end

local function read_dword(file)
  local bytes = file:read(4)
  if (not bytes or #bytes < 4) then 
    return nil 
  else
    return bit.bor(bytes:byte(1),
      bit.lshift(bytes:byte(2), 8),
      bit.lshift(bytes:byte(3), 16),
      bit.lshift(bytes:byte(4), 24))  
  end   
end

-- and so on (adapt as needed to mess with endianess!) ...

local file = io.open("some_binary_file.bin", "rb")

local bytes = file:read(512)

if (not bytes or #bytes < 512) then 
  print("unexpected end of file")
else
  for i = 1, #bytes do
    print(bytes:byte(i))
  end
end
    
print(read_word(file) or "unexpected end of file")
print(read_dword(file) or "unexpected end of file")


-- more bit manipulation? -> See "bit" in "StandardLuaApi.txt"

--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
