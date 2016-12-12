push = require("lib/push")
screen = require("lib/shack")
flux = require("lib/flux")

mainstate = require("mainstate")
menustate = require("menustate")

local currentstate = nil

gameWidth, gameHeight = 256, 144
local windowWidth, windowHeight = gameWidth*3, gameHeight*3

function switchState(state)
  if currentstate then
    if currentstate.quit then
      currentstate:quit()
    end
  end
  currentstate = state
end

function love.load()
  love.graphics.setDefaultFilter('nearest', 'nearest', 8)
  push:setupScreen(gameWidth, gameHeight, windowWidth, windowHeight, {fullscreen = false, resizable = true})
  screen:setDimensions(push:getDimensions())

  switchState(menustate:new())
end

function love.update(dt)
  flux.update(dt)
  screen:update(dt)
  if currentstate then
    if currentstate.update then
      currentstate:update(dt)
    end
  end
end

function love.draw()
  push:start()
  screen:apply()
  if currentstate then
    if currentstate.draw then
      currentstate:draw()
    end
  end
  push:finish()
end

function love.keypressed(key, scancode, isRepeat)
  if key == "p" then
    if not isRepeat then
      love.graphics.newScreenshot():encode("png", os.time() .. ".png")
    end
  end
  if currentstate then
    if currentstate.keypressed then
      currentstate:keypressed(key, scancode, isRepeat)
    end
  end
end

function love.quit()
  if currentstate then
    if currentstate.quit then
      currentstate:quit()
    end
  end
end

function love.resize(w, h)
  push:resize(w, h)
end
