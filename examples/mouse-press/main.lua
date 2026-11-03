--[[
  Mouse Press.

  Move the mouse to position the shape.
  Press the mouse button to invert the color

  Adapted from Processing examples. Adapted to L5 2025. Licensed under CC BY-NC-SA 4.0.
]] --
require("L5")

function setup()
    size(640, 360)
    windowTitle("Mouse Press")
    describe("Move and press the mouse button to position the shape and invert the color")

    noSmooth()
    fill(126)
    background(102)
end

function draw()
    if mouseIsPressed then
        stroke(255)
    else
        stroke(0)
    end

    line(mouseX - 66, mouseY, mouseX + 66, mouseY)
    line(mouseX, mouseY - 66, mouseX, mouseY + 66)
end
