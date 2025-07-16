require("L5")

function setup()
  size(400,400)
  windowTitle("keyIsDown example")
end

function draw()
  background(220)

  if keyIsPressed then
    print("You are holding down the "..key.." key")
  else
    print("not holding down a key")
  end

  if keyIsDown('space') then
    print("you pressed space")
  end
end

