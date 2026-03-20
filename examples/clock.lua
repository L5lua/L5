--[[
  Clock.

  The current time can be read with the second(), minute(),
  and hour() functions. In this example, sin() and cos() values
  are used to set the position of the hands
  
  Adapted from Processing examples. Adapted to L5 2025. Licensed under CC BY-NC-SA 4.0.
]] --
require("L5")

local cx, cy
local secondsRadius
local minutesRadius
local hoursRadius
local clockDiameter

function setup()
    size(640, 360)
    windowTitle("Clock")
    describe("Display the current time")

    stroke(255)

    local radius = min(width, height) / 2
    secondsRadius = radius * 0.72
    minutesRadius = radius * 0.60
    hoursRadius = radius * 0.50
    clockDiameter = radius * 1.8

    cx = width / 2
    cy = height / 2
end

function draw()
    background(0)

    -- Draw the clock background
    fill(80)
    noStroke()
    ellipse(cx, cy, clockDiameter, clockDiameter)

    -- Angles for sin() and cos() start at 3 o'clock;
    -- subtract HALF_PI to make them start at the top
    local s = map(second(), 0, 60, 0, TWO_PI) - HALF_PI
    local m = map(minute() + map(second(), 0, 60, 0, 1), 0, 60, 0, TWO_PI) - HALF_PI
    local h = map(hour() + map(minute(), 0, 60, 0, 1), 0, 24, 0, TWO_PI * 2) - HALF_PI

    -- Draw the hands of the clock
    stroke(255)
    strokeWeight(1)
    line(cx, cy, cx + cos(s) * secondsRadius, cy + sin(s) * secondsRadius)
    strokeWeight(2)
    line(cx, cy, cx + cos(m) * minutesRadius, cy + sin(m) * minutesRadius)
    strokeWeight(4)
    line(cx, cy, cx + cos(h) * hoursRadius, cy + sin(h) * hoursRadius)

    -- Draw the minute ticks
    strokeWeight(2)
    for a = 0, 354, 6 do
        local angle = radians(a)
        local x = cx + cos(angle) * secondsRadius
        local y = cy + sin(angle) * secondsRadius
        point(x, y)
    end
end