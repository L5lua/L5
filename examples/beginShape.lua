require("L5")

function setup() 
  size(400, 400)
  windowTitle("beginShape() example")
  
  fill(0)
  beginShape()
  for i=0,10 do
    vertex(random(width),random(height))
  end
  endShape()
  describe("custom shape with beginShape() function, vertices and endShape()")
end
