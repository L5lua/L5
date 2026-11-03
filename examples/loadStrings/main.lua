require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  describe("A sketch that loads in a file of names of Sun Ra Arkestra members. Clicking in the window prints out a random member of the orchestra and their instrument and year joined.")

  names = loadStrings("assets/names.txt")

  print("And this next track features a solo from Sun Ra Arkestra member...")
end

function mousePressed()
  print(random(names))
end
