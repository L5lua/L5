require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  describe("A sketch that loads in a CSV file of names of Sun Ra Arkestra members and prints out their info.")

  bandmembers = loadTable("assets/bandmembers.csv")
  for row, values in ipairs(bandmembers) do
	  print("row="..row.." count="..#values.." values=", unpack(values))
  end
  
  print("Just the band members' names:")
  for i=1,#bandmembers do
    print(bandmembers[i][1])
  end

end
