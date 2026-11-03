--[[
  Keyboard Functions

  Click on the window to give it focus and press the letter keys to type colors.
  The keyboard function keyPressed() is called whenever a key is pressed. 
  keyPressed() is another keyboard function that is called when a key is released.

  Adapted from Processing examples. Adapted to L5 2025. Licensed under CC BY-NC-SA 4.0.

  Original 'Color Typewriter' concept by John Maeda.
]] --
require("L5")

local maxHeight = 40
local minHeight = 20
local letterHeight = maxHeight
local letterWidth = 20

local x = -letterWidth
local y = 0

local newletter = false

local numChars = 26
local colors = {}

function setup()
    size(640, 360)
    windowTitle("Keyboard Functions")
    describe("Press letter keys to create forms in time and space")

    noStroke()
    colorMode(HSB, numChars)
    background(numChars / 2)

    -- Set a hue value for each key
    for i = 0, numChars - 1 do
        colors[i] = color(i, numChars, numChars)
    end
end

function draw()
    if newletter == true then
        -- Draw the "letter"
        local y_pos
        if letterHeight == maxHeight then
            y_pos = y
            rect(x, y_pos, letterWidth, letterHeight)
        else
            y_pos = y + minHeight
            rect(x, y_pos, letterWidth, letterHeight)
            fill(numChars / 2)
            rect(x, y_pos - minHeight, letterWidth, letterHeight)
        end
        newletter = false
    end
end

function textinput(text)    
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    if string.match(key, "^[A-Z]$") then
        keyIndex = string.find(alphabet, key) - 1
        letterHeight = maxHeight
        fill(colors[keyIndex])
    elseif string.match(key, "^[a-z]$") then
        keyIndex = string.find(alphabet, string.upper(key)) - 1
        letterHeight = minHeight
        fill(colors[keyIndex])
    else
        fill(0)
        letterHeight = 10
    end

    newletter = true

    -- Update the "letter" position
    x = x + letterWidth

    -- Wrap horizontally
    if x > width - letterWidth then
        x = 0
        y = y + maxHeight
    end

    -- Wrap vertically
    if y > height - letterHeight then
        y = 0
    end
end