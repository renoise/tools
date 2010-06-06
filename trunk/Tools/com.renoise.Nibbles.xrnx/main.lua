--[[----------------------------------------------------------------------------
Variables & Globals
----------------------------------------------------------------------------]]--

local matrix_width = 25
local matrix_height = 25
local matrix_colors = table.create{'black','blue','yellow'} --Bitmaps dir
local score = 0
local snake = table.create()
local vb = renoise.ViewBuilder()
local current_direction = "up"
local current_dialog = nil
local food_x = 6;
local food_y = 6;


--[[----------------------------------------------------------------------------
Functions
----------------------------------------------------------------------------]]--

-- Reset
function reset()
  score = 0
  vb = renoise.ViewBuilder()
  snake = table.create()
  current_direction = "up"
  snake[1] = { x= 1, y= round(matrix_height / 2) }
  snake[2] = { x= 1, y= round(matrix_height / 2) + 1 }
  snake[3] = { x= 1, y= round(matrix_height / 2) + 2 }
end


--[[
This function initializes some graphics, scores, and uniquely
identifies renoise.ViewBuilder() objects so they can be manipulated

vb:column are identified as: col_%
vb:row are identified as: cell_x%_y%
vb:bitmap are identifed as: bitmap_x%_y%

Where % is a wildcard for x,y coordinates on a grid. We use these vb
variables throughout the program.
]]--
function init()
  math.randomseed(os.time())
  reset()
  for x = 1, matrix_width do
    vb:column {
      id = "col_" .. x,
    }
    for y = 1, matrix_height do
      vb:row {
        id = "cell_x" .. x .. "y" .. y,
      }
      vb:bitmap {
        id = "bitmap_x" .. x .. "y" .. y,
        bitmap = "Bitmaps/cell_black.png",
      }
    end
  end

end


-- This function uses vb.views[] which was populated by init_objects() to show
-- our custom dialog.
function grid()

  if (current_dialog and current_dialog.visible) then
    -- Reset
    current_dialog:close()
    current_dialog = nil
  end

  local dialog_content = vb:row { }
  for x = 1, matrix_width do
    local tmp = "col_" .. x
    for y = 1, matrix_height do
      local tmp2 = "cell_x" .. x .. "y" .. y
      local tmp3 = "bitmap_x" .. x .. "y" .. y
      vb.views[tmp2]:add_child(vb.views[tmp3])
      vb.views[tmp]:add_child(vb.views[tmp2])
    end
    dialog_content:add_child(vb.views[tmp])
  end
  current_dialog = renoise.app():show_custom_dialog("Nibbles", dialog_content, key_handler)

end


-- Snake block
function create_snake_block()
  return {["x"] = nil, ["y"] = nil}
end


-- Draw snake
function draw_snake()
  for i = 1,  table.count(snake) do
    set_cell(snake[i].x, snake[i].y)
  end
end


-- Round a number
function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


-- Set a cell
function set_cell(x, y, color)
  if color == nil then color = "blue" end
  local tmp = "bitmap_x" .. x .. "y" .. y
  if vb.views[tmp] ~= nil and table.find(matrix_colors, color) then
    vb.views[tmp].bitmap = "Bitmaps/cell_" .. color .. ".png"
  end
end


-- Clear a cell
function clear_cell(x, y)
  local tmp = "bitmap_x" .. x .. "y" .. y
  if vb.views[tmp] ~= nil then
    vb.views[tmp].bitmap = "Bitmaps/cell_black.png"
  end
end


-- Get the color of a cell
function get_cell_color(x ,y)
  local tmp = "bitmap_x" .. x .. "y" .. y
  if vb.views[tmp] ~= nil then
    local pos = string.find(vb.views[tmp].bitmap, "Bitmaps/cell_")
    local color = string.sub(vb.views[tmp].bitmap, pos + 13)
    pos = string.find(color, ".png")
    color = string.sub(color, 1, -pos)
    if (table.find(matrix_colors, color) ~= nil) then
      return color
    end
  end
end


-- Keyboard input
function key_handler(dialog, mod_string, key_string)

  if (key_string == "esc") then
    dialog:close()
  elseif (
    key_string == "up" or
    key_string == "down" or
    key_string == "left" or
    key_string == "right"
  )
  then
    current_direction = key_string
    -- TODO, game() doesn't belong here...
    -- But I don't have a loop in main() that works yet..
    game()
  end

end


-- Game logic
function game()

  draw_snake()

  local tempBlock = create_snake_block() --Init with empty/useless coordinates
  local t1 = create_snake_block() --Ditto

  local col = get_cell_color(snake[1].x, snake[1].y);

  -- Do not allow the food to be on snake's mouth
  while (food_x == snake[1].x and food_y == snake[1].y) do
    food_x = math.random(matrix_width)
    food_y = math.random(matrix_height)
  end

  set_cell(food_x, food_y, "yellow")

  tempBlock.x = snake[1].x
  tempBlock.y = snake[1].y

  clear_cell(snake[1].x, snake[1].y)

  if(current_direction == "up") then
    snake[1].y = snake[1].y - 1
  elseif(current_direction == "down") then
    snake[1].y = snake[1].y + 1
  elseif(current_direction == "left") then
    snake[1].x = snake[1].x - 1
  elseif(current_direction == "right") then
    snake[1].x = snake[1].x + 1
  else
    return
  end

  if(
    snake[1].x < 1 or
    snake[1].x > matrix_width or
    snake[1].y < 1 or
    snake[1].y > matrix_height or
    col == get_cell_color(snake[1].x, snake[1].y)
    )
  then
    -- TODO
    renoise.app():show_error("Game over! You're score is: " .. score)
    current_dialog:close()
    main()
  end

  if(snake[1].x == food_x and snake[1].y == food_y) then
    clear_cell(food_x, food_y);
    snake[#snake + 1] = create_snake_block()
    snake[#snake].x = snake[#snake-1].x + 1
    snake[#snake].y = snake[#snake-1].y
    food_x = math.random(matrix_width)
    food_y = math.random(matrix_height)
    score = score + 1;
  end

  for i=2, table.count(snake) do
    clear_cell(snake[i].x, snake[i].y);
    t1.x = snake[i].x;
    t1.y = snake[i].y;
    snake[i].x = tempBlock.x;
    snake[i].y = tempBlock.y;
    tempBlock.x = t1.x;
    tempBlock.y = t1.y;
  end

  draw_snake()

end


-- Main
function main()

  init()
  grid()

  -- TODO, this loop doesn't work...
  -- while true do
    game()
    -- sleep(1)
  --end

end


--[[----------------------------------------------------------------------------
Menu Registration
----------------------------------------------------------------------------]]--

-- Randomize GUI
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Nibbles...",
  invoke = main
}