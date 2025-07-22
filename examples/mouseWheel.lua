require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  txt=""
end

function draw()
  background(255)
  fill(0)
  text(txt,10,10)
end

function mouseWheel(_x,_y)
    if _y > 0 then
        txt = "Mouse wheel moved up"
    elseif _y < 0 then
        txt = "Mouse wheel moved down"
    end
    print("x moved ".._x..", y moved ".._y)
end
