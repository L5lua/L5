require("L5")

function setup()
  size(800,600)
  windowTitle("Pong")
  rectMode(CENTER)
  p1 = {
    x=15,
    y=height/2,
    w=30,
    h=120,
    score=0
  }
  p2 = {
    x=width-15,
    y=height/2,
    w=30,
    h=120,
    score=0,
    yspeed=5
  }
  b = {
    x=width/2,
    y=height/2,
    w=30,
    h=30,
    xspeed=random(3,10),
    yspeed=random(3,10),
  }
end

function draw()
  background(180,0,180)

  --left
  fill(0,255,0)
  rect(p1.x,p1.y,p1.w,p1.h)

  --right
  fill(0,0,255)
  rect(p2.x,p2.y,p2.w,p2.h)

  --ball
  fill(200,0,0)
  ellipse(b.x,b.y,b.w,b.h)

  --scores
  fill(0)
  text(p1.score,width/4,20)
  text(p2.score,3/4*width,20)

  -- player movement
  p1.y=mouseY
  if b.y<p2.y then
    p2.y=p2.y-p2.yspeed
  else
    p2.y=p2.y+p2.yspeed
  end

  -- ball movement
  b.x=b.x+b.xspeed
  b.y=b.y+b.yspeed
  if b.x>width or b.x<0 then 
    b.xspeed = b.xspeed * -1 
  end
  if b.y>height or b.y<0 
    then b.yspeed = b.yspeed * -1 
  end
  if b.x<0 then 
    p2.score=p2.score+1 
  end
  if b.x>width 
    then p1.score=p1.score+1 
  end

  --hide cursor on screen
  if mouseX>0 and mouseX<width then
    noCursor()
  else
    cursor()
  end

  --collision
  --player1
  if b.x<p1.x+p1.w/2 and b.y < p1.y+p1.h/2 and b.y> p1.y-p1.h/2 then
    b.x=b.x+10
    b.xspeed=b.xspeed*-1
  end
  --player2
  if b.x>p2.x-p2.w/2 and b.y > p2.y-p2.h/2 and b.y < p2.y+p2.h/2 then
    b.x=b.x-10
    b.xspeed=b.xspeed*-1
  end

end

