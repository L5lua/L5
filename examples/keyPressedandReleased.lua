require("L5")

function setup()
  size(400,400)
  windowTitle("keyIsDown example")
end

function draw()
  background(220)

end


function keyPressed()
  print("you pressed a key down")
end

function keyReleased()
  print("you let go of a key")
end
