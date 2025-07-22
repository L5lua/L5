require("L5")

function setup()
  size(710,400)
  rectMode(CENTER)
  setPositionAndColor()
end

function setPositionAndColor()
  circleX=random(width)
  circleY=random(height)
  r,g,b=random(255),random(255),random(255)
end

function draw()
  background(10)

  fill(r,g,b)
  circle(circleX,circleY,100)
end

function mousePressed()
  setPositionAndColor()
end
