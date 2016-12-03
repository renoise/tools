--[[============================================================================
vMetrics
============================================================================]]--
--[[

This class contains static methods for string measurement

]]

class 'vMetrics'

vMetrics.GLYPH_NORMAL_FALLBACK = 6
vMetrics.GLYPH_NORMAL = {
  [" "]=3,
  ["!"]=4,
  ["#"]=8,
  ["'"]=3,
  ["*"]=5,
  ["@"]=8,
  ["£"]=5,
  ["€"]=5, -- 28  {226,130,172}
  ["["]=5,
  ["]"]=5,    
  ["µ"]=5, -- 12  {194,181}
  [","]=3,
  ["-"]=4,
  ["."]=3,
  ["A"]=7,  
  ["B"]=7,
  ["C"]=8,
  ["D"]=9,
  ["E"]=7,
  ["G"]=8,
  ["H"]=8,
  ["I"]=3,
  ["J"]=3,
  ["K"]=7,
  ["M"]=9,
  ["N"]=8,
  ["O"]=8,
  ["P"]=7,
  ["Q"]=8,
  ["R"]=7,
  ["S"]=7,
  ["T"]=4,
  ["U"]=8,
  ["V"]=7,
  ["W"]=9,
  ["Y"]=7,
  ["c"]=5,
  ["f"]=4,
  ["i"]=2,
  ["j"]=2,
  ["k"]=5,
  ["l"]=2,
  ["m"]=10,
  ["r"]=4,
  ["s"]=5,
  ["t"]=4,
  ["w"]=8,
  ["¨"]=4,
  ["å"]=5, -- 12  {195,165}
  ["æ"]=7, -- 12  {195,166}
  ["ø"]=7, -- 12  {195,184}
  ['"']=5,  
  ['%']=10,
  ['&']=9,
  ['(']=4,
  [')']=4,
  ['/']=3,
  ['=']=8,
  ['?']=5,
  ['^']=8,
  ['`']=5,
  ['¤']=5, -- 12  {194,164}

}

vMetrics.GLYPH_BIG_FALLBACK = 8
vMetrics.GLYPH_BIG = {
  ["m"]=13,
}

vMetrics.GLYPH_BOLD_FALLBACK = 7
vMetrics.GLYPH_BOLD = {} -- TODO

vMetrics.GLYPH_ITALIC_FALLBACK = 7
vMetrics.GLYPH_ITALIC = {} -- TODO

vMetrics.GLYPH_MONO_FALLBACK = 6
vMetrics.GLYPH_MONO = {} -- TODO

--------------------------------------------------------------------------------

function vMetrics.locate_glyphs(font)
  TRACE("vMetrics.locate_glyphs(font)",font)

  local glyphs,fallback 
  if (font == "normal") then
    glyphs = vMetrics.GLYPH_NORMAL
    fallback = vMetrics.GLYPH_NORMAL_FALLBACK
  elseif (font == "big") then
    glyphs = vMetrics.GLYPH_BIG
    fallback = vMetrics.GLYPH_BIG_FALLBACK
  elseif (font == "bold") then
    glyphs = vMetrics.GLYPH_BOLD
    fallback = vMetrics.GLYPH_BOLD_FALLBACK
  elseif (font == "italic") then
    glyphs = vMetrics.GLYPH_ITALIC
    fallback = vMetrics.GLYPH_ITALIC_FALLBACK
  elseif (font == "mono") then
    glyphs = vMetrics.GLYPH_MONO
    fallback = vMetrics.GLYPH_MONO_FALLBACK
  else
    error("Unsupported 'font'")
  end

  return glyphs,fallback

end

--------------------------------------------------------------------------------
-- calculate the width of a given string
-- @param str (string)
-- @param font (string), see vTextField.FONT

function vMetrics.get_text_width(str,font)
  TRACE("vMetrics.get_text_width(str,font)",str,font)

  assert(type(str)=="string")
  assert(type(font)=="string")

  local glyphs,fallback = vMetrics.locate_glyphs(font)
  local num_chars = #str
  local width = 10 -- margin

  for k = 1,num_chars do    
    local chr = string.sub(str,k,k)
    if glyphs[chr] then
      width = width+glyphs[chr]
    else
      -- TODO look up multibyte (UTF-8) characters
      width = width+fallback
    end
  end

  return width

end

--------------------------------------------------------------------------------
-- create a string which can fit in a given space 
-- @param str (string)
-- @param max_width (int), width in pixels
-- @param font (string), see vTextField.FONT

function vMetrics.fit_text(str,max_width,font)

  assert(type(str)=="string")
  assert(type(max_width)=="number")
  assert(type(font)=="string")

  local glyphs,fallback = vMetrics.locate_glyphs(font)
  local num_chars = #str
  local width = 0

  for k = 1,num_chars do    
    local chr = string.sub(str,k,k)
    if glyphs[chr] then
      width = width+glyphs[chr]
    else
      width = width+fallback
    end
    if (width > max_width) then
      return string.sub(str,1,k-1)
    end
  end

  return str

end




