require("L5")

function setup()
  size(720,400)

  background(220);

  square(20, 20, 100);

  rect(100, 40, 200, 100);

  ellipse(540, 100, 300, 100);

  circle(560, 100, 100);

  arc(540, 100, 300, 100, 180, 360, CHORD);

  line(20, 200, 200, 350);

  triangle(250, 350, 350, 200, 450, 350);

  quad(500, 250, 550, 200, 700, 300, 650, 350);
end

