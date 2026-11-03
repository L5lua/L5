--[[
  Easing.

  Move the mouse across the screen and the symbol will follow.
  Between drawing each frame of the animation, the program
  calculates the difference between the position of the
  symbol and the curson. If the difference is larger than 
  1 pixel, the symbol moves part of the distance (0.05) from its
  current position toward the cursor.

  Adapted from Processing examples. Adapted to L5 2025. Licensed under CC BY-NC-SA 4.0.
]] --
require("L5")

local x = 0
local y = 0
local easing = 0.05

function setup()
    size(640, 360)
    windowTitle("Easing")
    describe(" Move the mouse across the screen and the symbol will follow.")

    noStroke()
end

function draw()
    background(51)

    -- Change the position of the drawn ellipse to the position of the mouse with easing

    targetX = mouseX
    dx = targetX - x
    x = x + dx * easing

    targetY = mouseY
    dy = targetY - y
    y = y + dy * easing

    ellipse(x, y, 66)
end