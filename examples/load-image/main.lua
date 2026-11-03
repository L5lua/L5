require("L5")

function setup()
  size(500,500)
  windowTitle("My sketch")
  cat = loadImage("assets/cat.png")
end

function draw()
  image(cat,0,0,250,height)
end
