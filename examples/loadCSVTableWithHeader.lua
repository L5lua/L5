require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  describe("A sketch that loads in a CSV file of names of Sun Ra Arkestra members and prints out their info.")

  bandmembers = loadTable("assets/bandmembersWithHeader.csv","header")
 
  print("Just the band members' instruments:")
  for i=1,#bandmembers do
    print(bandmembers[i].instrument)
  end

end
