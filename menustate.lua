local menustate = {}

function menustate:new()
  local state = {
    assets = {}
  }

  state.assets.background = love.graphics.newImage("assets/menu.png")
  state.assets.tinyfont = love.graphics.newFont("assets/kenpixel_mini_square.ttf", 8)
  state.assets.smallfont = love.graphics.newFont("assets/kenpixel_mini_square.ttf", 8)
  state.assets.bigfont = love.graphics.newFont("assets/kenpixel_mini_square.ttf", 8*5)

  state.selectedOption = 1
  state.menuOptions = {}

  -- Start option
  local startOption = {}
  startOption.text = "Start"

  function startOption:execute()
    switchState(mainstate:new())
  end

  table.insert(state.menuOptions, startOption)

  -- Quit option
  local quitOption = {}
  quitOption.text = "Quit"

  function quitOption:execute()
    love.event.quit()
  end

  table.insert(state.menuOptions, quitOption)


  function state:update(dt)
  end

  function state:draw()
    love.graphics.draw(state.assets.background)
    love.graphics.setFont(state.assets.smallfont)

    for i, option in ipairs(state.menuOptions) do
      if state.selectedOption == i then
        love.graphics.setColor(132, 126, 135, 255)
      else
        love.graphics.setColor(43, 43, 43, 255)
      end
      love.graphics.print(option.text, 16, 32+i*8)
    end

    love.graphics.setColor(43, 43, 43, 255)
    love.graphics.setFont(state.assets.tinyfont)

    love.graphics.print("Game by @felipeac", 16, 112-8)
    love.graphics.print("Music by Matthew Pablo", 16, 112)
    love.graphics.print("http://www.matthewpablo.com", 16, 112+8)
  end

  function state:keypressed(key, scancode, isRepeat)
    if not isRepeat then
      if key == "up" or key == "w" or key == "k" then
        if state.menuOptions[state.selectedOption-1] then
          state.selectedOption = state.selectedOption - 1
        end
      end
      if key == "down" or key == "s" or key == "j" then
        if state.menuOptions[state.selectedOption+1] then
          state.selectedOption = state.selectedOption + 1
        end
      end
      if key == "return" or key == "space" or key == "right" or key == "d" or key == "l" then
        state.menuOptions[state.selectedOption]:execute()
      end
    end
  end

  function state:quit()
  end

  return state
end

return menustate
