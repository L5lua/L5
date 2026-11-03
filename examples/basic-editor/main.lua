-- Examples share the same L5.lua file, so tell LÖVE where require() can find it
package.path = package.path .. ";" .. love.filesystem.getSource() .. "/../../?.lua"

require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
end

function draw()
  background(220)
end
