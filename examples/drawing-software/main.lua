-- Examples share the same L5.lua file, so tell LÖVE where require() can find it
package.path = package.path .. ";" .. love.filesystem.getSource() .. "/../../?.lua"

require("L5")

function setup()
  size(800,600)
  windowTitle("My sketch")
  fill("hotpink")
  background("midnightblue")
  noStroke()
end

function mouseDragged()
  circle(mouseX,mouseY,20)
end

function mousePressed()
  fill(random(255),random(255),random(255))
end
