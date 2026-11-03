require("L5")
-- adapted from p5.js reference noise() CC BY-NC-SA 4.0

function setup()
  size(100,100)
  windowTitle("Noise sketch")

  describe('A black dot moves randomly on a gray square.')
end

function draw() 
  background(200)

  -- Calculate the coordinates.
  local x = 100 * noise(0.005 * frameCount)
  local y = 100 * noise(0.005 * frameCount + 10000)

  -- Draw the point.
  strokeWeight(5)
  point(x, y)
end
