--[[============================================================================
main.lua
============================================================================]]--

-- Variables & Globals

local matrix_width = 25
local matrix_height = 25
local matrix_cells = table.create{}
local matrix_view = nil
local matrix_colors = table.create{'black','blue','yellow'} --Bitmaps dir

local color_bg = "black"
local color_snake = "blue"
local color_food = "yellow"

local current_dialog = nil
local score = 0
local snake = table.create()
local food = { x= 6, y= 6 }
local current_direction = "up"
local last_idle_time = os.clock()

--------------------------------------------------------------------------------
-- The Game
--------------------------------------------------------------------------------

-- Reset Game

function reset()
  math.randomseed(os.time())

  for x = 1,#matrix_cells do
    for y = 1,#matrix_cells[x] do
      clear_cell(x, y)
    end
  end

  snake = table.create()
  snake[1] = { x= 1, y= math.floor(matrix_height / 2) }
  snake[2] = { x= 1, y= math.floor(matrix_height / 2) + 1 }
  snake[3] = { x= 1, y= math.floor(matrix_height / 2) + 2 }

  current_direction = "up"
  score = 0

  draw_snake()
end


--------------------------------------------------------------------------------

-- Create main matrix cells

function create_cells()
  local vb = renoise.ViewBuilder()
  matrix_view = vb:row { }

  for x = 1, matrix_width do
    local column = vb:column { }
    matrix_cells[x] = table.create()

    for y = 1, matrix_height do
       matrix_cells[x][y] = vb:bitmap {
        bitmap = "Bitmaps/cell_" .. color_bg .. ".bmp",
      }
      column:add_child(matrix_cells[x][y])
    end

    matrix_view:add_child(column)
  end
end


--------------------------------------------------------------------------------

-- Draw snake

function draw_snake()
  for _,point in pairs(snake) do
    set_cell_color(point.x, point.y, color_snake)
  end
end


--------------------------------------------------------------------------------

-- Move snake

function move_snake()
  set_cell_color(snake[1].x, snake[1].y, color_snake)
  set_cell_color(snake[2].x, snake[2].y, color_snake)
end


--------------------------------------------------------------------------------

-- Access a cell in the matrix view

function matrix_cell(x, y)
  if (matrix_cells[x] ~= nil) then
    return matrix_cells[x][y]
  else
    return nil
  end
end


--------------------------------------------------------------------------------

-- Get the color of a cell

function get_cell_color(x ,y)
  local cell = matrix_cell(x, y)

  if (cell ~= nil) then
    local pos = cell.bitmap:find("Bitmaps/cell_")
    local color = cell.bitmap:sub(pos + 13)

    pos = color:find(".bmp")
    color = color:sub(1, -pos)

    return color
  end
end


--------------------------------------------------------------------------------

-- Set a cells color

function set_cell_color(x, y, color)
  assert(matrix_colors:find(color), "invalid color")

  local cell = matrix_cell(x, y)
  if (cell ~= nil) then
    matrix_cells[x][y].bitmap = "Bitmaps/cell_" .. color .. ".bmp"
  end
end


--------------------------------------------------------------------------------

-- Clear a cell

function clear_cell(x, y)
  set_cell_color(x, y, color_bg)
end


--------------------------------------------------------------------------------

-- Keyboard input

function key_handler(dialog, key)

  if (key.name == "esc") then
    dialog:close()

  elseif (
    (key.name == "up" and current_direction ~= "down") or
    (key.name == "down" and current_direction ~= "up") or
    (key.name == "left" and current_direction ~= "right") or
    (key.name == "right" and current_direction ~= "left")
  )
  then
    current_direction = key.name
  end

end


--------------------------------------------------------------------------------

-- Start running the game logic (frame timer)

function run()
  if not (renoise.tool().app_idle_observable:has_notifier(game)) then
    renoise.tool().app_idle_observable:add_notifier(game)
  end
end


--------------------------------------------------------------------------------

-- Stop running the game (frame timer)

function stop()
  if (renoise.tool().app_idle_observable:has_notifier(game)) then
    renoise.tool().app_idle_observable:remove_notifier(game)
  end
end


--------------------------------------------------------------------------------

-- Game logic (frame timer)

function game()

  -- Game was closed?
  if (not current_dialog or not current_dialog.visible) then
    stop()
    return
  end

  -- Only run every 0.1 seconds
  if (os.clock() - last_idle_time < 0.1) then
    return
  end

  -- Do frame stuff
  local tmp1 = table.create{x=nil, y=nil} --Init with empty/useless coordinates
  local tmp2 = table.create{x=nil, y=nil} --Ditto

  -- Do not allow the food to be on snake's mouth
  while get_cell_color(food.x, food.y ) == color_snake do
    food.x = math.random(matrix_width)
    food.y = math.random(matrix_height)
  end
  set_cell_color(food.x, food.y, color_food)

  tmp1.x = snake[1].x
  tmp1.y = snake[1].y

  -- Check the direction
  if (current_direction == "up") then
    snake[1].y = snake[1].y - 1
  elseif (current_direction == "down") then
    snake[1].y = snake[1].y + 1
  elseif (current_direction == "left") then
    snake[1].x = snake[1].x - 1
  elseif (current_direction == "right") then
    snake[1].x = snake[1].x + 1
  else
    return
  end

  -- Snake crashed
  if (
    snake[1].x < 1 or
    snake[1].x > matrix_width or
    snake[1].y < 1 or
    snake[1].y > matrix_height or
    color_snake == get_cell_color(snake[1].x, snake[1].y)
    )
  then
    renoise.app():show_error("Game over! Your score is: " .. score)
    current_dialog:show()
    reset()

    return
  end

  -- Snake ate some food, so he grows
  if (snake[1].x == food.x and snake[1].y == food.y) then
    -- Grow
    clear_cell(food.x, food.y)
    snake[#snake + 1] = table.create{x=nil, y=nil}
    snake[#snake].x = snake[#snake-1].x
    snake[#snake].y = snake[#snake-1].y
    -- New food
    food.x = math.random(matrix_width)
    food.y = math.random(matrix_height)
    -- Increment score
    score = score + 1
  end

  -- Move the snake
  clear_cell(snake[#snake].x, snake[#snake].y)
  for i=2, table.count(snake) do
    tmp2.x = snake[i].x
    tmp2.y = snake[i].y
    snake[i].x = tmp1.x
    snake[i].y = tmp1.y
    tmp1.x = tmp2.x
    tmp1.y = tmp2.y
  end

  -- Update cells
  move_snake()

  -- Memorize time for the frame timer
  last_idle_time = os.clock()

end


--------------------------------------------------------------------------------

-- Initializes and shows the game

function create_game()

  if (not current_dialog or not current_dialog.visible) then
    create_cells()
    reset()
    run()

    current_dialog = renoise.app():show_custom_dialog(
      "Nibbles", matrix_view, key_handler)
  end

end


--------------------------------------------------------------------------------
-- Menu Registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Nibbles...",
  invoke = create_game
}

