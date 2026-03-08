--[[
  Mouse Press.

  Move the mouse to position the shape.
  Press the mouse button to invert the color

  Adapted from Processing Examples website.
  https://processing.org/examples/mousepress.html
]] --
require("L5")

function setup()
    size(640, 360)
    windowTitle("Mouse Press")
    describe("Move and press the mouse button to position the shape and invert the color")

    -- Draw Modes
    noSmooth()
    fill(126)
    background(102)
end

function draw()
    -- In processing mousePressed is both a function signature and global built-in variable 
    -- In L5, this is differentiated into mousePressed(), the function and mouseIsPressed, the built-in variable
    if (mouseIsPressed) then
        stroke(255)
    else
        stroke(0)
    end

    line(mouseX - 66, mouseY, mouseX + 66, mouseY)
    line(mouseX, mouseY - 66, mouseX, mouseY + 66)
end
