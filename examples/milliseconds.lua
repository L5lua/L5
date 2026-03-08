--[[
  Milliseconds.

  A millisecond is 1/1000 of a second.
  L5 keeps track of the number of miliseconds a program has run.
  By modifying this number with the modulo(%) operator,
  different patterns in time are created.

  Adapted from Processing Examples website.
  https://processing.org/examples/milliseconds.html
]] --
require("L5")

function setup()
    size(640, 360)
    windowTitle("Milliseconds")
    describe("How L5 keeps track of the number of milliseconds a program has run")

    noStroke()
    scale = width / 20
end

function draw()
    for i = 0, scale do
        colorMode(RGB, (i + 1) * scale * 10)
        fill(millis() % ((i + 1) * scale * 10))
        rect(i * scale, 0, scale, height)
    end
end
