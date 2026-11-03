require("L5")

function setup()
  size(800,600)
  windowTitle("My sketch")
  fill("hotpink")
  background("midnightblue")
  noStroke()
end

function mouseDragged()
  circle(mouseX,mouseY,20)
end

function mousePressed()
  fill(random(255),random(255),random(255))
end
