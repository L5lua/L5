require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")

  describe("A sketch that demonstrates mouseWheel function which takes two optional arguments. Scrolling up turns the screen light blue, while scrolling down turns it light green.")
  textSize(14)
  txt=""
end

function draw()
  fill(0)
  text(txt,10,10)
end

function mouseWheel(_x,_y)  
  print("scrolling")
  if _y > 0 then
      txt = "Mouse wheel moved up"
      background("lightblue")
  elseif _y < 0 then
      txt = "Mouse wheel moved down"
      background("lightgreen")
  end
  print("x moved ".._x..", y moved ".._y)  
end
