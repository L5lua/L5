require("L5")
--adapted from Processing textAlign example CC BY NC SA 4.0

function setup()
  size(400,400)
  windowTitle("textAlign2 example")
  describe("Second textAlign example, using second parameter for vertical-alignment. Text is printed in large letters, center in a column: CENTER, BOTTOM on top with a line underneath. Then CENTER, CENTER with a line through. Underneath is CENTER, TOP with a line above.")

  background(0)
  stroke(153)
  textSize(44)
  textAlign(CENTER, BOTTOM)
  line(0, 120, width, 120)
  text("CENTER,BOTTOM", 200, 120)
  textAlign(CENTER, CENTER)
  line(0, 200, width, 200)
  text("CENTER,CENTER", 200, 200)
  textAlign(CENTER, TOP)
  line(0, 280, width, 280)
  text("CENTER,TOP", 200, 280)
end
