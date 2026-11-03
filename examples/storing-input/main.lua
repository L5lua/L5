--[[
  Storing Input.

  Move the mouse across the screen to change the position
  of the circles. The positions of the mouse are recorded
  into an array and played back every frame. Between each
  frame, the newest value are added to the end of each array
  and the oldest value is deleted

  Adapted from Processing examples. Adapted to L5 2025. Licensed under CC BY-NC-SA 4.0.
]] --
require("L5")

local num = 60
local mx
local my

function setup()
    size(640, 360)
    windowTitle("Storing Input")
    describe(" Move the mouse across the screen to change the position of the circles and store them")

    noStroke()

    mx = {}
    my = {}

    for i = 0, num - 1 do
        mx[i] = 0
        my[i] = 0
    end

    fill(255, 153)
end

function draw()
    background(51)

    -- Cycle through the array, using a different entry on each frame.
    -- Using modulo (%) like this is faster than moving all the values over
    local which = frameCount % num
    mx[which] = mouseX
    my[which] = mouseY

    for i = 0, num - 1 do
        -- which+1 is the smallest (the oldest in the array)
        local index = (which + 1 + i) % num
        ellipse(mx[index], my[index], i, i)
    end
end