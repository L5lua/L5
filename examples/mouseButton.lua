require("L5")

function setup()
  size(400,400)
  windowTitle("mouseButton example")

  describe("A sketch that demonstrates detecting mouseButton presses. Pressing the left mouse button draws a filled black square in the top left. Right clicking draws that square in white. Center clicking turns it gray.")
end

function draw()
  rect(25, 25, 50, 50);
end

function mousePressed()
  if mouseButton == LEFT then
    fill(0)
  elseif mouseButton == RIGHT then
    fill(255)
  else 
    fill(126)
  end
end
