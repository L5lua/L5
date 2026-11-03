require("L5")

function setup()
    size(400, 400)
    windowTitle("My L5 Sketch")

    describe("A sketch with a blue circle that follows the mouse and overlaid welcome text Hello L5!")
end

function draw()
    background(220)

    -- Draw a circle that follows the mouse
    fill(100, 150, 200)
    circle(mouseX, mouseY, 50)

    -- Draw some text
    fill(0)
    text("Hello L5!", 20, 30)
end
