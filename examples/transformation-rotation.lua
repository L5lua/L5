require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  rectMode(CENTER)
  angleMode(DEGREES)
  angle=45
end

function draw()
  --background(120,120,120)  -- Clear the canvas each frame
  strokeWeight(2)
  stroke(255,0,0)  -- Red stroke
  fill(0,0,255)    -- Blue fill
  
  translate(width/2, height/2)  -- Move to center
  rotate(angle)
  rect(0, 0, 100, 100)  -- Draw rectangle centered at origin
  angle=angle+1
end
