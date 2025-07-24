require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  describe("A sketch that saves a list of the original Migos rappers as lines in a text file.")

  local myData = {"Quavo", "Offset", "Takeoff"}
  if saveStrings(myData, "assets/migos.txt") then
    print("File saved successfully!")
  end

end
