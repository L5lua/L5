require("L5")
--adapted from Processing colorMode() reference CC BY NC SA

function setup()
  size(400,400)

noStroke()
colorMode(RGB, 400)
  for i=0,400 do 
    for j=0,400 do
      stroke(i, j, 0)
      point(i, j)
    end
  end

  describe("A gradient of dark green to red to orange to yellow to green starting top left moving clockwise.")
end
