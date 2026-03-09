require("L5")

function setup() 
  size(400, 400)
  windowTitle("beginShape(TRIANGLES) example")
  
  fill(0)
  beginShape(TRIANGLES);

  -- Left triangle
  vertex(30, 75);
  vertex(40, 20);
  vertex(50, 75);

  -- Right triangle
  vertex(60, 20);
  vertex(70, 75);
  vertex(80, 20);

  endShape();

  describe("custom shape with beginShape(TRIANGLES) function, vertices and endShape()")
end