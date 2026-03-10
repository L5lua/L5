require("L5")

function setup()
  size(400, 400)
  windowTitle("texture() example")
  textureMode(NORMAL)

  cat = loadImage("examples/assets/cat.png")

  beginShape(TRIANGLES)
  texture(cat)
  vertex(50,  100, 0,    0.2)
  vertex(50,  300, 0,    1)
  vertex(150, 50,  0.33, 0)
  vertex(150, 300, 0.33, 1)
  vertex(250, 100, 0.67, 0.2)
  vertex(250, 300, 0.67, 1)
  vertex(350, 50,  1,    0)
  vertex(350, 300, 1,    1)
  endShape()

  describe("Wrapping a mesh texture around a custom shape with coordinates specified with u,v")
end