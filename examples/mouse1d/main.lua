--[[
  Mouse 1D.

  Move the mouse left and right to shift the balance.
  The "mouseX" variable is used to control both the
  size and color of the rectangles.

  Adapted from Processing examples. Adapted to L5 2025. Licensed under CC BY-NC-SA 4.0.
]] --
require("L5")

function setup()
    size(640, 360)
    windowTitle("Mouse 1D")
    describe("Move the mouse left and right to shift the balance.")

    noStroke()
    colorMode(RGB, height, height, height)
    rectMode(CENTER)
end

function draw()
    background(0.0)

    local r1 = map(mouseX, 0, width, 0, height)
    local r2 = height - r1

    fill(r1)
    rect(width / 2 + r1 / 2, height / 2, r1, r1)

    fill(r2)
    rect(width / 2 - r2 / 2, height / 2, r2, r2)
end