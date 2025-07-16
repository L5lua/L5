require("L5")

function setup()
  --size(400,400) --gets overridden in next line anyway
  fullscreen(true)
  windowTitle("My sketch")
end

function draw()
  background(220)

  if fullscreen() then
    background(255,0,0)
  else
    background(0)
  end
end

function mousePressed()
  exit()
end
