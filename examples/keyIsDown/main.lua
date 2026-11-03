require("L5")

function setup()
  size(400,400)
  windowTitle("keyIsDown example")
end

function draw()
  background(220)

  if keyIsDown('a') and keyIsDown('b') then
    print("you pressed both")
  elseif keyIsDown('a') then
    print("you pressed a")
  elseif keyIsDown('b') then
    print("you pressed b")
  else
    print("nothing pressed")
  end
end

