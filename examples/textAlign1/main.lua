require("L5")
--adapted from Processing textAlign example CC BY NC SA 4.0

function setup()
  size(400,400)
  windowTitle("textAlign example")
  describe("Example sketch with letters ABCD aligned to the right, above EFGH center-aligned and IJKL aligned to the left.")

  background(0)
  textSize(64)
  textAlign(RIGHT)
  text("ABCD", 200, 120)
  textAlign(CENTER)
  text("EFGH", 200, 200)
  textAlign(LEFT)
  text("IJKL", 200, 280)
end
