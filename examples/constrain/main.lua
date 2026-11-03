--[[
  Constrain.

  Move the mouse across the screen to move the circle.
  The program constrains the circle to its box.

  Adapted from Processing examples. Adapted to L5 2025. Licensed under CC BY-NC-SA 4.0.
]] --
require("L5")

local mx = 0
local my = 0
local easing = 0.05
local radius = 24
local edge = 100
local inner = edge + radius

function setup()
    size(640, 360)
    windowTitle("Constrain")
    describe(" Move the mouse across the screen to move the circle. The program constrains the circle to its box.")

    noStroke()
    ellipseMode(RADIUS)
    rectMode(CORNERS)
end

function draw()
    background(51)

    -- Change the position of the drawn ellipse to the position of the mouse with easing
    if (abs(mouseX - mx) > 0.1) then
        mx = mx + (mouseX - mx) * easing
    end

    if (abs(mouseY - my) > 0.1) then
        my = my + (mouseY - my) * easing
    end

    -- Constrain the position of the ellipse to the inner rectangle
    mx = constrain(mx, inner, width - inner)
    my = constrain(my, inner, height - inner)
    fill(76)
    rect(edge, edge, width - edge, height - edge)
    fill(255)
    ellipse(mx, my, radius, radius)
end