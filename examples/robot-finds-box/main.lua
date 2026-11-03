require("L5")

function setup()
  size(400,400)
  robotImg = loadImage("assets/robot.png")
  imageMode(CENTER)
  box = {
    x=width/2,
    y=height/2,
    pickup=false,
    display = function(self)
      fill("gold")
      square(box.x,box.y,20)
    end,
    move = function(self)
      if box.pickup then
	box.x=robot.x
	box.y=robot.y
      end
      if box.x<10 or box.x>width-10 or box.y>height-10 or box.y<10 then
	box.pickup = false
      end
    end
  }
  robot = {
    x=width,
    y=height/2,
    xspeed=random(-4,-2),
    yspeed=1,
    w=30,
    c=0,
    display = function(self)
      fill("aquamarine")
      --circle(robot.x,robot.y,30)
      image(robotImg,robot.x,robot.y,80,50)
    end,
    move = function(self)
      robot.x=robot.x+robot.xspeed
      robot.y=robot.y+robot.yspeed
      if robot.y>height or robot.y<0 then robot.yspeed=robot.yspeed*-1 end
      if robot.x>width or robot.x<0 then robot.xspeed=robot.xspeed*-1 end
    end,
    pickup = function(self)
      if dist(robot.x,robot.y,box.x,box.y) < 40 then
	box.pickup = true
      end
    end
  }
end
function draw()
  background("lightblue")
  box.move()
  box.display()
  robot.display()
  robot.move()
  robot.pickup()
end
