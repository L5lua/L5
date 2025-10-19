require ('L5')

function setup() 
  size(100, 100)

  windowTitle("Looping example")
  describe('A white circle drawn against a gray background. When the user double-clicks, the circle stops or resumes following the mouse.')
end

function draw() 
  background(200)

  -- Draw the circle at the mouse's position.
  circle(mouseX, mouseY, 20)
end

-- Toggle the draw loop when the user clicks
function mousePressed() 
  if isLooping() == true then
    noLoop()
  else 
    loop()
  end
end
