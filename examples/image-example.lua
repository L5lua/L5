require("L5")

function setup()
  size(500,500)
  windowTitle("My sketch")
  tuxdog = loadImage("assets/tuxdog.png")
  imageMode(CENTER)
  noCursor()
end

function draw()
  --background(255,200)
  image(tuxdog,mouseX,mouseY,250,250)
end

function mousePressed()
  background(random(255),random(255),random(255))
end
