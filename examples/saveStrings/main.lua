-- Examples share the same L5.lua file, so tell LÖVE where require() can find it
package.path = package.path .. ";" .. love.filesystem.getSource() .. "/../../?.lua"

require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  describe("A sketch that saves a list of the original Migos rappers as lines in a text file.")

  local myData = {"Quavo", "Offset", "Takeoff"}
  -- Save file into the LÖVE save directory for this sketch
  -- see https://love2d.org/wiki/love.filesystem.getSaveDirectory
  if saveStrings(myData, "migos.txt") then
    print("File saved successfully!")
  end

end
