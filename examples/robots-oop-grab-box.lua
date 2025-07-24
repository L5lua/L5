require("L5")

-- The robot class definition below could all be moved to separate file Robot.lua 
-- and then required here: local Robot = require("robot")
Robot = {}
Robot.__index = Robot -- tells Lua to use the Robot's metatable to find methods to run (rather than directly placing a method inside each individual robot instance)

-- Define a method in the Robot class
function Robot:new(x, y, w, h)
  local robot = {
    x = x or random(width), 
    y = y or random(height), 
    w = w or 70, 
    h = w or 70, 
    xspeed = random(-2, 2), 
    yspeed = random(-2, 2)
  }
  setmetatable(robot, Robot)  -- This links the instance to Robot
  return robot
end

function Robot:move()
  self.x = self.x + self.xspeed 
  self.y = self.y + self.yspeed
  if self.y>height or self.y<0 then self.yspeed=self.yspeed*-1 end
  if self.x>width or self.x<0 then self.xspeed=self.xspeed*-1 end
end

function Robot:display()
  --fill("aquamarine")
  --circle(robot.x,robot.y,30)
  image(robotImg,self.x,self.y,self.w,self.h)
end

-- Box object with metamethods, no "class" structure
box = {
  x=nil, --can't initialize to random(width) since random seeded after setup runs
  y=nil,
  size=40,
  display = function(self)
    square(self.x,self.y,self.size)
  end,
  move = function(self)
    for i=1,#robots do
      if dist(self.x,self.y,robots[i].x,robots[i].y) < self.size then
        self.x=robots[i].x    
	self.y=robots[i].y
	break
      end
    end
  end
}

-- Global vars
robots = {} -- initialize a table to hold the robots
robotImg = nil

function setup()
  size(800,600)

  robotImg = loadImage("assets/robot.png")
  imageMode(CENTER)
  rectMode(CENTER)
  strokeWeight(3)
  fill("gold")
  stroke("goldenrod")

  box.x=random(width)
  box.y=random(height)

  for i = 1, 10 do
    table.insert(robots, Robot:new())
  end
end

function draw()
  background("lightblue")
  box:move()
  box:display()
  for i=1,10 do
    robots[i]:move()
    robots[i]:display()
  end
end
