require("L5")

function setup() 
  size(400, 400)
  windowTitle("beginShape(LINES) example")
  
  fill(0)
  beginShape(LINES)
  for i=0,10 do
    vertex(random(width),random(height))
  end
  endShape()
  describe("custom shape with beginShape(LINES) function, vertices and endShape()")
end