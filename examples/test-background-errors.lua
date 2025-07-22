require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
end

function draw()

  rect(0,0,100,100)

  if mouseX>width/2 then
    background(255,0,0)
  end

end

function keyTyped()
  if key=='c' then
    background(0,0,255)
  elseif key == 'p' then
    background(255,0,255)
  end
end

function mousePressed()
  background(0,255,0)
end
