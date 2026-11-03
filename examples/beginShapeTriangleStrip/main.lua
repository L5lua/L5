require("L5")

function setup()
  size(400, 400)
  windowTitle("beginShape(TRIANGLE_STRIP) example")

  fill(255, 180, 100)
  stroke(51)
  strokeWeight(2)

  beginShape(TRIANGLE_STRIP)
  vertex(50,  100)
  vertex(50,  300)
  vertex(150, 50)
  vertex(150, 300)
  vertex(250, 100)
  vertex(250, 300)
  vertex(350, 50)
  vertex(350, 300)
  endShape()

  describe("ribbon of triangles drawn with beginShape(TRIANGLE_STRIP), with stroke")
end
