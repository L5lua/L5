require("L5")

function setup() 
  size(400, 400)
  windowTitle("beginShape(POINTS) example")
  
  fill(0)
  beginShape(POINTS)
  for i=0,10 do
    vertex(random(width),random(height))
  end
  endShape()
  describe("custom shape with beginShape(POINTS) function, vertices and endShape()")
end