--[[
  Mouse 2D.

  Moving the mouse changes the position and size of each box

  Adapted from Processing examples. Adapted to L5 2025. Licensed under CC BY-NC-SA 4.0.
]] --
require("L5")

function setup()
    size(640, 360)
    windowTitle("Mouse 2D")
    describe("Moving the mouse changes the position and size of each box")

    noStroke()
    rectMode(CENTER)
end

function draw()
    background(0.0)

    fill(255, 204)
    rect(mouseX, height / 2, mouseY / 2 + 10, mouseY / 2 + 10)

    fill(255, 204)

    local inverseX = width - mouseX
    local inverseY = height - mouseY
    rect(inverseX, height / 2, (inverseY / 2) + 10, (inverseY / 2) + 10)
end