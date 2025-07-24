require("L5")

function setup()
  size(400,400)
  windowTitle("My sketch")
  describe("A sketch that loads in a lua file of names of Sun Ra Arkestra members and prints out their info.")

  bandmembers = loadTable("assets/bandmembers.tsv","header")
 
for i, member in ipairs(bandmembers) do
  print(member.name .. " plays " .. member.instrument)
  if member.joined then
    print("  (joined in " .. member.joined .. ")")
  end
end

  print()
  print("Longest member: "..bandmembers[1].name)
  print("Most recent member: "..bandmembers[#bandmembers].name)

end
