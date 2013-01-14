--[[============================================================================
main.lua
============================================================================]]--

-- Variables & Globals

-- Table to hold nibbles game values
local nibbles = table.create()
function get_nibbles()
    --Pass globals to external files with this function
    return nibbles
end

-- Include FastTracker levels
require "ft_levels"

local vb = nil

nibbles.matrix_width = 51
nibbles.matrix_height = 23
nibbles.matrix_cells = table.create{}
nibbles.matrix_view = nil
nibbles.matrix_colors = table.create{'grid','wall1','wall2','wall3','renlogo','snake'} --Bitmaps dir

nibbles.color_bg = "grid"
nibbles.color_snake = "snake"
nibbles.color_food = "renlogo"

nibbles.current_dialog = nil
nibbles.score = 0
nibbles.snake = table.create()
nibbles.food = { x= 0, y= 0 }
nibbles.current_direction = "up"
nibbles.last_idle_time = os.clock()
nibbles.update_frequency = 0.1 --GUI refresh in seconds

nibbles.grid = true
nibbles.keycheck = 1
nibbles.pause = true
nibbles.wrap = false

nibbles.grow_amount = 4 -- This gets calculated again dynamically
nibbles.level_score = 0
nibbles.level_score_goal = 9
nibbles.lives = 3

nibbles.current_level = 1

nibbles.food_area = 
{
    --minimum x to have food appear
    x_min = 1,
    --maximum x to have food appear
    x_max = 51,
    --minimym y to have food appear
    y_min = 1,
    --maximum y to have food appear
    y_max = 23,
}

-- Setup levels rotation table
nibbles.levels =
{
    ftlevel_1,ftlevel_2,ftlevel_3,ftlevel_4,ftlevel_5,
    ftlevel_6,ftlevel_7,ftlevel_8,ftlevel_9,ftlevel_10,
    ftlevel_11,ftlevel_12,ftlevel_13,ftlevel_14,ftlevel_15,
    ftlevel_16,ftlevel_17,ftlevel_18,ftlevel_19,ftlevel_20,
    ftlevel_21,ftlevel_22,   
    ftlevel_23,ftlevel_24,
    ftlevel_25,
    ftlevel_26,
    ftlevel_27,ftlevel_28,
    ftlevel_29,
    ftlevel_30,ftlevel_31,ftlevel_32,ftlevel_33,ftlevel_34,ftlevel_35,
    ftlevel_36,ftlevel_37,ftlevel_38,ftlevel_39
}

-- Initialize high score prefrences

local prefs = renoise.Document.create("ScriptingToolPreferences")
{
    high_score = 0
}
renoise.tool().preferences = prefs


--------------------------------------------------------------------------------
-- The Game
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Reset Game

function reset()

    nibbles.score = 0
    nibbles.level_score = 0
    nibbles.lives = 3
    nibbles.grow_amount = 4
    
    nibbles.current_level = 1
      
    update_information()
      
    draw_level(true)
    draw_snake()
    place_draw_new_food()

end

--------------------------------------------------------------------------------
-- Clear all matrix cells

function clear_cells()

    for x = 1,#nibbles.matrix_cells do
        for y = 1,#nibbles.matrix_cells[x] do
            clear_cell(x, y)
        end
    end

end

--------------------------------------------------------------------------------
-- Create the options view and playing surface matrix cells

function create_options_matrix()

    nibbles.matrix_view = vb:row {}
 
    local options = vb:column 
    {
      spacing = 15,
         
      vb:column 
      {      
        vb:bitmap {
          bitmap = "Bitmaps/nibbles.bmp"
        },          
        vb:text {
          font = "mono",
          text = 'Game Speed:'
        },
        vb:switch {
          items = {"FAST","NORM","SLOW"},
          width = 116,
          value = 2,
          notifier = function(new_index)
            if new_index == 1 then nibbles.update_frequency = 0.05 end
            if new_index == 2 then nibbles.update_frequency = 0.1 end
            if new_index == 3 then nibbles.update_frequency = 0.2 end
          end
        }
      },
      vb:column 
      {
        spacing = 15,

        vb:column 
        {
          vb:row 
          {
            vb:text {
              font = "mono",
              text = 'Show Grid?    '
            },
            vb:checkbox {
              value = true,
              notifier = function(value)
                nibbles.grid = value
                if value == true then 
                  nibbles.color_bg = 'grid'
                  nibbles.matrix_colors[1] = 'grid'
                else
                  nibbles.color_bg = 'black'
                  nibbles.matrix_colors[1] = 'black'
                end
                           
                draw_level(false)
                draw_snake()
                draw_food()
              end
            }
          },
          vb:row 
          {
            vb:text {
                font = "mono",
                text = 'Wrap Snake?   '
              },
              vb:checkbox {
                value = false,
                notifier = function(value)
                  nibbles.wrap = value
                end
              }
          }  
        },                
          
        vb:column 
        {
          vb:switch {
          items = {"PLAY","PAUSE"},
          width = 116,
          value = 2,
          notifier = function(new_index)
            if new_index == 1 then nibbles.pause = false end
            if new_index == 2 then nibbles.pause = true end
          end
          }
        },       
        vb:column 
        {
          vb:text {
            id = "HScoreText",
            font = "mono"   
          },
          vb:text {
            id = "ScoreText",
            font = "mono"
          },
          vb:text {
            id = "LivesText",
            font = "mono"
          },
          vb:text {
            id = "LevelText",
            font = "mono"
          },
          vb:text {
            id = "FoodText",
            font = "mono"
          }
        }        
     }
   }
   
   --Finally add that to our view
   nibbles.matrix_view:add_child(options)

    --Create the main matrix cells for the playing surface
    for x = 1, nibbles.matrix_width do
        local column = vb:column { }
        nibbles.matrix_cells[x] = table.create()

        for y = 1, nibbles.matrix_height do
            nibbles.matrix_cells[x][y] = vb:bitmap {
                bitmap = "Bitmaps/cell_" .. nibbles.color_bg .. ".bmp",
            }
            column:add_child(nibbles.matrix_cells[x][y])
        end

        nibbles.matrix_view:add_child(column)
    end

end

--------------------------------------------------------------------------------
-- Update the side panel information

function update_information()

    vb.views.HScoreText.text = "High Score :" .. prefs.high_score.value
    vb.views.ScoreText.text = "Score      :" .. nibbles.score
    vb.views.LivesText.text = "Lives      :" .. nibbles.lives
    vb.views.LevelText.text = "Level      :" .. nibbles.current_level
    vb.views.FoodText.text = "Coll. Food :" .. nibbles.level_score

end


--------------------------------------------------------------------------------
-- Draw a level

function draw_level(Startupdate)

    local indx = 1    
    for y = 1, nibbles.matrix_height do
      for x = 1, nibbles.matrix_width do
          local chr = nibbles.levels[nibbles.current_level][indx]
          -- A wall?
          if chr < 0x10 then
            set_cell_color(x, y, nibbles.matrix_colors[chr + 1])
          else
            set_cell_color(x, y, nibbles.matrix_colors[1])           
          end
          if Startupdate == true then
            -- Starting snake position?
            if chr == 0xf0 then
              snake_start(x, y, "up")
            end
            if chr == 0xf1 then
              snake_start(x, y, "left")
            end
          end   
          indx = indx + 1
      end
    end

end

--------------------------------------------------------------------------------
-- Access a cell in the matrix view

function matrix_cell(x, y)

    if (nibbles.matrix_cells[x] ~= nil) then
        return nibbles.matrix_cells[x][y]
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
        color = color:sub(1, pos - 1)

        return color
    end

end

--------------------------------------------------------------------------------
-- Set a cells color

function set_cell_color(x, y, color)

    assert(nibbles.matrix_colors:find(color), "invalid color")

    local cell = matrix_cell(x, y)
    if (cell ~= nil) then
        nibbles.matrix_cells[x][y].bitmap = "Bitmaps/cell_" .. color .. ".bmp"
    end

end

--------------------------------------------------------------------------------
-- Clear a cell

function clear_cell(x, y)

    set_cell_color(x, y, nibbles.color_bg)

end


--------------------------------------------------------------------------------
-- Draw food into the display

function draw_food()

    set_cell_color(nibbles.food.x, nibbles.food.y, nibbles.color_food)

end

--------------------------------------------------------------------------------
-- New food

function place_draw_new_food()

    local new_food = table.create()
    repeat
      local fa = nibbles.food_area
        new_food.x = fa.x_min + math.random(fa.x_max - fa.x_min)
        new_food.y = fa.y_min + math.random(fa.y_max - fa.y_min)
    until get_cell_color(new_food.x, new_food.y) == nibbles.color_bg

    nibbles.food.x = new_food.x
    nibbles.food.y = new_food.y

    --Draw the food into the display
    draw_food()
    
end


--------------------------------------------------------------------------------
-- Reset snake and place it

function snake_start(start_x, start_y, start_direction, start_length)

    -- Default start length at map/level start
    if not start_length then
        start_length = 3
    end
    -- Create snake table
    nibbles.snake = table.create()
    for i = 1, start_length do
        nibbles.snake[i] = { x = start_x, y = start_y }
    end
    -- Set direction
    nibbles.current_direction = start_direction

end

--------------------------------------------------------------------------------
-- Draw snake

function draw_snake()

    for _,point in pairs(nibbles.snake) do
        set_cell_color(point.x, point.y, nibbles.color_snake)
    end

end

--------------------------------------------------------------------------------
-- Move snake

function move_draw_snake(tmp1,tmp2)

    --erase tail end of snake
    if nibbles.snake[#nibbles.snake].x ~= nibbles.snake[#nibbles.snake-1].x or
      nibbles.snake[#nibbles.snake].y ~= nibbles.snake[#nibbles.snake-1].y then
        clear_cell(nibbles.snake[#nibbles.snake].x, nibbles.snake[#nibbles.snake].y)
    end
  
    --move snake positions
    for i=2, table.count(nibbles.snake) do
        tmp2.x = nibbles.snake[i].x
        tmp2.y = nibbles.snake[i].y
        nibbles.snake[i].x = tmp1.x
        nibbles.snake[i].y = tmp1.y
        tmp1.x = tmp2.x
        tmp1.y = tmp2.y
    end

    --draw snake 
    set_cell_color(nibbles.snake[1].x, nibbles.snake[1].y,nibbles.color_snake) 

end

--------------------------------------------------------------------------------
-- Grow the snake

function grow_snake()

    -- Snake ate some Food, so he grows
    for _ = 1, nibbles.grow_amount do
        nibbles.snake[#nibbles.snake + 1] = table.create{x=nil, y=nil}
        nibbles.snake[#nibbles.snake].x = nibbles.snake[#nibbles.snake-1].x
        nibbles.snake[#nibbles.snake].y = nibbles.snake[#nibbles.snake-1].y
    end
    
    -- Update the grow amount
    nibbles.grow_amount = (nibbles.level_score + 1) * 4

    -- Increment players score
    nibbles.score = nibbles.score + 1
    nibbles.level_score = nibbles.level_score + 1

    if nibbles.score > prefs.high_score.value then
        prefs.high_score.value = nibbles.score
    end
        
    -- Update information
    update_information()
    
    -- Calculate and draw up some new food placement
    place_draw_new_food()   

end


--------------------------------------------------------------------------------
-- Snake crash!

function snake_crash()
      
    nibbles.lives = nibbles.lives - 1
    if nibbles.lives == 0 then
      renoise.app():show_error(
      "Game over!\n" .. "\nYour score is: " .. nibbles.score ..
      "\nYour high score is: " .. prefs.high_score.value
      )
      nibbles.current_dialog:show()

      reset()

    else
      renoise.app():show_error(
      "Crashed!\n" .. "\nNumber of lives left: " .. nibbles.lives .. "\nYour score is: " .. nibbles.score ..
      "\nYour high score is: " .. prefs.high_score.value
      )
      nibbles.current_dialog:show()
          
      nibbles.grow_amount = 4
      nibbles.level_score = 0

      --Update side panel
      update_information()
      
      draw_level(true)
      draw_snake()
      place_draw_new_food()
    end

end


--------------------------------------------------------------------------------
-- Keyboard input handler

function key_handler(dialog, key)

    if (key.name == "esc") then
        dialog:close()
    elseif nibbles.pause == true then
      return
          
    elseif (
        (key.name == "up" and nibbles.current_direction ~= "down") or
        (key.name == "down" and nibbles.current_direction ~= "up") or
        (key.name == "left" and nibbles.current_direction ~= "right") or
        (key.name == "right" and nibbles.current_direction ~= "left")
        )
        then
            if (nibbles.keycheck == 1) then
              nibbles.current_direction = key.name
              nibbles.keycheck = 0
            end
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
    if (not nibbles.current_dialog or not nibbles.current_dialog.visible) then
        stop()
        return
    end

    -- Only run every update_frequency seconds
    if (os.clock() - nibbles.last_idle_time < nibbles.update_frequency) then
        return
    end
    
    --Are we paused?, if so just return    
    if nibbles.pause == true then
        return
    end
    
    --Unlock the keyboard (this flag is to stop you from bumping into yourself so easily :) )
    nibbles.keycheck = 1
    
    --Next level?
    if nibbles.level_score == nibbles.level_score_goal then
        renoise.app():show_message(
        "Level finished!\n" .. "\nYour score is: " .. nibbles.score ..
        "\nYour high score is: " .. prefs.high_score.value ..
        "\nNumber of lives left: " .. nibbles.lives
        )
        nibbles.current_dialog:show()
       
        nibbles.current_level = nibbles.current_level + 1
        if nibbles.current_level > #nibbles.levels then
          nibbles.current_level = 1
        end

        --Draw new level, snake and food
        draw_level(true)
        draw_snake()
        place_draw_new_food()
               
        nibbles.level_score = 0
        nibbles.grow_amount = (nibbles.level_score + 1) * 4

        --Update side panel        
        update_information()
        
        return
    end
    
    -- Do frame stuff
    local tmp1 = table.create{x=nil, y=nil} --Init with empty/useless coordinates
    local tmp2 = table.create{x=nil, y=nil} --Ditto

    tmp1.x = nibbles.snake[1].x
    tmp1.y = nibbles.snake[1].y  
    
    -- Check the direction
    if (nibbles.current_direction == "up") then
        nibbles.snake[1].y = nibbles.snake[1].y - 1
    elseif (nibbles.current_direction == "down") then
        nibbles.snake[1].y = nibbles.snake[1].y + 1
    elseif (nibbles.current_direction == "left") then
        nibbles.snake[1].x = nibbles.snake[1].x - 1
    elseif (nibbles.current_direction == "right") then
        nibbles.snake[1].x = nibbles.snake[1].x + 1
    else
        return
    end

    -- Check if our snake crashed into the sides if no wrap is enabled
    if (nibbles.wrap ~= true) then
      if (nibbles.snake[1].x < 1 or nibbles.snake[1].x > nibbles.matrix_width or
        nibbles.snake[1].y < 1 or nibbles.snake[1].y > nibbles.matrix_height) then
            snake_crash()         
            return
      end
    end   

    --Do any wrap
    if nibbles.snake[1].y <= 0 then nibbles.snake[1].y = nibbles.matrix_height
    elseif nibbles.snake[1].y >= nibbles.matrix_height+1 then nibbles.snake[1].y = 0 end
    if nibbles.snake[1].x <= 0 then nibbles.snake[1].x = nibbles.matrix_width
    elseif nibbles.snake[1].x >= nibbles.matrix_width+1 then nibbles.snake[1].x = 0 end


    --Now check walls and snake collision
    if (nibbles.color_snake == get_cell_color(nibbles.snake[1].x, nibbles.snake[1].y) or
        'wall1' == get_cell_color(nibbles.snake[1].x, nibbles.snake[1].y) or
        'wall2' == get_cell_color(nibbles.snake[1].x, nibbles.snake[1].y) or
        'wall3' == get_cell_color(nibbles.snake[1].x, nibbles.snake[1].y)) then
          snake_crash()    
          return
    end

    -- Move and update the snake
    move_draw_snake(tmp1,tmp2)

    -- Check if the snake ate some food, if so grow!
    if (nibbles.snake[1].x == nibbles.food.x and nibbles.snake[1].y == nibbles.food.y) then
        grow_snake()
    end  
 
         
    -- Memorize time for the frame timer
    nibbles.last_idle_time = os.clock()
    
end
  

--------------------------------------------------------------------------------
-- Initializes and shows the game

function create_game()

    if (not nibbles.current_dialog or not nibbles.current_dialog.visible) then

        --Seed the random number generator
        math.randomseed(os.time())  
        
        vb = renoise.ViewBuilder()

        nibbles.grid = true
        nibbles.wrap = false
        nibbles.matrix_colors[1] = "grid"
        nibbles.color_bg = "grid"
        nibbles.pause = true
        nibbles.keycheck = 1   
        nibbles.update_frequency = 0.1
        
        create_options_matrix(vb)
        
        reset()
        
        run()

        nibbles.current_dialog = renoise.app():show_custom_dialog(
        "Nibbles", nibbles.matrix_view, key_handler)
    end

end


--------------------------------------------------------------------------------
-- Menu Registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
    name = "Main Menu:Tools:Nibbles...",
    invoke = create_game
}

