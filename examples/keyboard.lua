--[[
  Keyboard.

  Click on the image to give it focus and press the letter keys
  to create forms in time and space. Each key has a unique identifying
  number. These numbers can be used to position shapes in space.

  Adapted from Processing Examples website.
  https://processing.org/examples/keyboard.html
]] --
require("L5")

-- Declare Variables
local rectWidth = width / 4

function setup()
    size(640, 360)
    windowTitle("Keyboard")
    describe("Press letter keys to create forms in time and space")

    -- Draw Modes
    noStroke()
    background(0)
end

function draw()
    -- Keep draw() heer to continue looping while waiting for keys
end

function keyPressed()
    local keyIndex = -1
    -- Convert the built-in key variable from a string to its byte value
    local keyByte = string.byte(key)

    if (keyByte >= string.byte('A') and keyByte <= string.byte('Z')) then
        keyIndex = keyByte - string.byte('A')
    elseif (keyByte >= string.byte('a') and keyByte <= string.byte('z')) then
        keyIndex = keyByte - string.byte('a')
    end

    if (keyIndex == -1) then
        -- If it's not a letter key, clear the screen
        background(0)
    else
        -- If it's a letter key, fill a rectangle
        fill(millis() % 255)
        x = map(keyIndex, 0, 25, 0, width - rectWidth)
        rect(x, 0, rectWidth, height)
    end
end
