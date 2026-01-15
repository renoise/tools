--[[============================================================================
cBitmap.lua
============================================================================]]--

class 'cBitmap'

--------------------------------------------------------------------------------
--- Basebones class for for creating .bmp files 
--  Each line is padded with zeroes, like this
--
--  |   |   |   |   |   |   |   |   |   |   |
--  ff66ccff66ccff66cc000000|   |   |   |   |
--  ff66ccff66ccff66ccff66cc|   |   |   |   |
--  ff66ccff66ccff66ccff66ccff66cc00|   |   |
--  ff66ccff66ccff66ccff66ccff66ccff66cc0000|

cBitmap.BIT_COUNT = {1,4,8,16,24,32}

--[[
cBitmap.BMP_COMPRESSION = {
  UNCOMPRESSED = 0,
  RLE_8 = 1,        -- Usable only with 8-bit images
  RLE_4 = 2,        -- Usable only with 4-bit images
  BITFIELDS = 3,    -- Used - and required - only with 16- and 32-bit images
}
]]

cBitmap.HEADER_SIZE = 54
cBitmap.PIXELS_PER_METER = 2834

function cBitmap:__init(...)

  local args = cLib.unpack_args(...)

	self.width = args.width or 100

	self.height = args.height or 100

  -- (cBitmap.BIT_COUNT) NB: only 24-bit is tested!!
	self.bit_count = args.bit_count or 24

	--self.compression = 0   -- uncompressed
	--self.size_image = 0    -- no need when uncompressed 
	--self.x_resolution = 0  -- preferred horizontal resolution 
	--self.y_resolution = 0  -- preferred vertical resolution 
	--self.clrs_used = 0     -- used Number Color Map entries 
	--self.clrs_important = 0 -- Number of significant colors

	self.pixels = {}

  -- internal -------------------------

  self.bitmap = {}
  


end

-------------------------------------------------------------------------------
--- set all pixels to a particular color

function cBitmap:flood(color)

  self.pixels = {}
  
  for k = 1,self.height*self.width do
    self.pixels[k] = color
  end
  
end

-------------------------------------------------------------------------------
--- given a value, return bytes in reverse (endian) order
-- @param num (number), treated as 32-bit 
-- @param endian (bool), whether to swap bytes or not
-- @return table>number

function cBitmap.split_bits(num,endian)

  local str_hex = (bit.tohex(num))
  local rslt = {}
  local bytes = {
    tonumber(string.sub(str_hex,1,2),16),
    tonumber(string.sub(str_hex,3,4),16),
    tonumber(string.sub(str_hex,5,6),16),
    tonumber(string.sub(str_hex,7,8),16),
  }
  if endian then
    for k,v in ripairs(bytes) do
      table.insert(rslt,v)
    end
  else
    rslt = bytes
  end
  
  return rslt

end

-------------------------------------------------------------------------------

function cBitmap:get_bytes_padding()
  --TRACE("cBitmap:get_bytes_padding()",self)
  return (self.width)%4
end

-------------------------------------------------------------------------------

function cBitmap:get_bitmap_size_in_bytes()
  --TRACE("cBitmap:get_bitmap_size_in_bytes()",self)
  local padding = self:get_bytes_padding()
  return (self.width*self.height*3) + padding*self.height+2
end

-------------------------------------------------------------------------------

function cBitmap:get_total_size_in_bytes()
  --TRACE("cBitmap:get_total_size_in_bytes()",self)
  return cBitmap.HEADER_SIZE + self:get_bitmap_size_in_bytes()
end

-------------------------------------------------------------------------------
--- this method will create the bitmap table

function cBitmap:create()

  self.bitmap = {}

  local size_bytes = cBitmap.split_bits(self:get_total_size_in_bytes(),true)
  local bitmap_bytes = cBitmap.split_bits(self:get_bitmap_size_in_bytes(),true)
  local width_bytes = cBitmap.split_bits(self.width,true)
  local height_bytes = cBitmap.split_bits(self.height,true)
  local ppm_bytes = cBitmap.split_bits(cBitmap.PIXELS_PER_METER,true)

  -- FILE HEADER ----------------------
  
  -- bitmap signature
  self.bitmap[1] = 'B'
  self.bitmap[2] = 'M'

  -- file size in bytes 
  for i = 3, 6 do self.bitmap[i] = size_bytes[i-2] end
  for i = 7, 10 do self.bitmap[i] = 0 end    -- reserved fields

  -- offset of pixel data (after header)
  self.bitmap[11] = cBitmap.HEADER_SIZE
  self.bitmap[12] = 0
  self.bitmap[13] = 0
  self.bitmap[14] = 0

  -- BITMAP HEADER --------------------

  -- header size
  self.bitmap[15] = 40
  for i = 16, 18 do self.bitmap[i] = 0 end
  for i = 19, 22 do self.bitmap[i] = width_bytes[i-18] end 
  for i = 23, 26 do self.bitmap[i] = height_bytes[i-22] end 
  
  self.bitmap[27] = 1  -- reserved field
  self.bitmap[28] = 0
  self.bitmap[29] = self.bit_count -- number of bits per pixel
  self.bitmap[30] = 0
  
  for i = 31, 34 do self.bitmap[i] = 0 end -- compression method 
  for i = 35, 38 do self.bitmap[i] = bitmap_bytes[i-34] end  
  for i = 39, 42 do self.bitmap[i] = ppm_bytes[i-38] end  
  for i = 43, 46 do self.bitmap[i] = ppm_bytes[i-42] end  
  for i = 47, 50 do self.bitmap[i] = 0 end -- color palette 
  for i = 51, 54 do self.bitmap[i] = 0 end -- # important colors

  -- PIXEL DATA -----------------------
  
  local num_pixel_bytes = self:get_bitmap_size_in_bytes()
  local padding = self:get_bytes_padding()

  --local row_idx = 1
  local col_idx = 1
  local pixel_idx = 1
  local write_pos = 55

  local bytes_per_row = self.width*3 + padding

  for i = 55, 55+num_pixel_bytes do 

    if (i < write_pos) then
      -- wait for counter to catch up
    else

      local bytes_written = 0
      local pixel

      -- write a line of pixels (3 bytes), pad if needed
      for col_idx = 0, self.width-1 do          
        pixel = self.pixels[pixel_idx]
        if pixel then
          local write_pos = i+(col_idx*3)
          self.bitmap[write_pos+0] = pixel[3]
          self.bitmap[write_pos+1] = pixel[2]
          self.bitmap[write_pos+2] = pixel[1]
          bytes_written = bytes_written + 3
          pixel_idx = pixel_idx + 1
        end
      end
      if pixel then
        if (bytes_written < bytes_per_row) then
          for pad_idx = 0,padding-1 do
            local write_pos = i+(self.width*3)+pad_idx
            self.bitmap[write_pos] = 0
          end
          bytes_written = bytes_written + padding
        end
      end
      write_pos = #self.bitmap+1

    end

  end


end

-------------------------------------------------------------------------------

function cBitmap:save_bmp(file_path)
  TRACE("cBitmap.save_bmp(file_path)",file_path)

  local fh = io.open(file_path,'wb')
  if not fh then
    error("failed to create file handler")
  end

  for k,v in ipairs(self.bitmap) do
    if (type(v)=="string") then
      fh:write(string.char(string.byte(v)))
    else
      fh:write(string.char(v))
    end
  end
  
  fh:close()

end

