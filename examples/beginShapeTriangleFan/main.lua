require("L5")

function setup() 
  size(400, 400)
  windowTitle("beginShape(TRIANGLE_FAN) example")

  fill(150, 200, 255)
  stroke(51)
  strokeWeight(5)

  beginShape(TRIANGLE_FAN)
  vertex(200, 200)  -- center
  vertex(200, 50)   -- top
  vertex(320, 110)
  vertex(370, 250)
  vertex(280, 370)
  vertex(120, 370)
  vertex(30,  250)
  vertex(80,  110)
  vertex(200, 50)
  endShape()

  describe("octagon drawn with beginShape(TRIANGLE_FAN) from a center point, with stroke")
end
