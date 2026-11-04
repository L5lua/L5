-- Examples share the same L5.lua file, so tell LÖVE where require() can find it
package.path = package.path .. ";" .. love.filesystem.getSource() .. "/../../?.lua"

require("L5")

function setup()
  size(400,400)
  windowTitle("Screenshot example")
  love.filesystem.setIdentity("screenshot_example")

  fill(random(255),random(255),random(255))
  circle(random(width),random(height),200)
end

function mousePressed()
  save()
end
