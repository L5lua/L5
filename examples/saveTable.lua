require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  describe("A sketch that saves a list of the original Migos rappers as data files: lua, csv and tsv.")

  local myData = {
    {name = "Quavo", instrument = "vocals"},
    {name = "Offset", instrument = "vocals"},
    {name = "Takeoff", instrument = "vocals"}
  }

  -- Explicitly specify format
  saveTable(myData, "migos.lua", "lua")
  saveTable(myData, "migos.csv", "csv") 

  -- Auto-detect from filename extension
  saveTable(myData, "migos.tsv")    -- Detects tsv format

end
