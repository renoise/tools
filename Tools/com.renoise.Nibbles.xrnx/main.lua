--[[----------------------------------------------------------------------------
Variables & Globals
----------------------------------------------------------------------------]]--

local current_dialog = nil

local matrix_width = 25
local matrix_height = 25
local matrix_colors = table.create{'black','blue','yellow'} --Bitmaps dir
local matrix_cells = table.create{}
local matrix_view = nil

local score = 0
local snake = table.create()
local food = { x= 6, y= 6 }
local current_direction = "up"
local last_idle_time = os.clock()


--[[----------------------------------------------------------------------------
Functions
----------------------------------------------------------------------------]]--

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


-- Create main matrix cells
function create_cells()
  local vb = renoise.ViewBuilder()
  matrix_view = vb:row { }

  for x = 1, matrix_width do
    local column = vb:column { }
    matrix_cells[x] = table.create()

    for y = 1, matrix_height do
       matrix_cells[x][y] = vb:bitmap {
        bitmap = "Bitmaps/cell_black.bmp",
      }
      column:add_child(matrix_cells[x][y])
    end

    matrix_view:add_child(column)
  end
end


-- Draw snake
function draw_snake()
  for _,point in pairs(snake) do
    set_cell_color(point.x, point.y, "blue")
  end
end


-- Access a cell in the matrix view
function matrix_cell(x, y)
  if (matrix_cells[x] ~= nil) then
    return matrix_cells[x][y]
  else
    return nil
  end
end


-- Get the color of a cell
function get_cell_color(x ,y)
  local cell = matrix_cell(x, y)

  if (cell ~= nil) then
    local pos = cell.bitmap:find("Bitmaps/cell_")
    local color = cell.bitmap:sub(pos + 13)

    pos = color:find(".bmp")
    color = color:sub(1, -pos)

    if (matrix_colors:find(color) ~= nil) then
      return color
    end
  end
end


-- Set a cells color
function set_cell_color(x, y, color)
  assert(matrix_colors:find(color), "invalid color")

  local cell = matrix_cell(x, y)
  if (cell ~= nil) then
    matrix_cells[x][y].bitmap = "Bitmaps/cell_" .. color .. ".bmp"
  end
end


-- Clear a cell
function clear_cell(x, y)
  set_cell_color(x, y, "black")
end


-- Keyboard input
function key_handler(dialog, key)

  if (key.name == "esc") then
    dialog:close()

  elseif (
    key.name == "up" or
    key.name == "down" or
    key.name == "left" or
    key.name == "right"
  )
  then
    current_direction = key.name
  end

end


-- Start running the game logic (frame timer)
function run()
  if not (renoise.tool().app_idle_observable:has_notifier(game)) then
    renoise.tool().app_idle_observable:add_notifier(game)
  end
end


-- Stop running the game (frame timer)
function stop()
  if (renoise.tool().app_idle_observable:has_notifier(game)) then
    renoise.tool().app_idle_observable:remove_notifier(game)
  end
end


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

  local color = get_cell_color(snake[1].x, snake[1].y);

  -- Do not allow the food to be on snake's mouth
  while (food.x == snake[1].x and food.y == snake[1].y) do
    food.x = math.random(matrix_width)
    food.y = math.random(matrix_height)
  end
  set_cell_color(food.x, food.y, "yellow")

  tmp1.x = snake[1].x
  tmp1.y = snake[1].y
  clear_cell(snake[1].x, snake[1].y)

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
    color == get_cell_color(snake[1].x, snake[1].y)
    )
  then
    renoise.app():show_error("Game over! You're score is: " .. score)
    current_dialog:show()
    reset()

    return
  end

  -- Snake ate some food, so he grows
  if (snake[1].x == food.x and snake[1].y == food.y) then
    -- Grow
    clear_cell(food.x, food.y);
    snake[#snake + 1] = table.create{x=nil, y=nil}
    snake[#snake].x = snake[#snake-1].x + 1
    snake[#snake].y = snake[#snake-1].y
    -- New food
    food.x = math.random(matrix_width)
    food.y = math.random(matrix_height)
    -- Increment score
    score = score + 1;
  end

  -- Move the snake
  for i=2, table.count(snake) do
    clear_cell(snake[i].x, snake[i].y);
    tmp2.x = snake[i].x;
    tmp2.y = snake[i].y;
    snake[i].x = tmp1.x;
    snake[i].y = tmp1.y;
    tmp1.x = tmp2.x;
    tmp1.y = tmp2.y;
  end

  -- Update cells
  draw_snake()

  -- Memorize time for the frame timer
  last_idle_time = os.clock()

end


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


--[[----------------------------------------------------------------------------
Menu Registration
----------------------------------------------------------------------------]]--

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Nibbles...",
  invoke = create_game
}
