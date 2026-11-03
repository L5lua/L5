require("L5")
--pawns game setup

function setup()
  size(400,400)
  windowTitle("Chess - starting position")
  ellipseMode(CORNER)
  imageMode(CENTER)

  --load images
  pawnw=loadImage("assets/chess/pawnw.png")
  pawnb=loadImage("assets/chess/pawnw.png")
  rookb=loadImage("assets/chess/rookb.png")
  rookw=loadImage("assets/chess/rookw.png")
  knightb=loadImage("assets/chess/knightb.png")
  knightw=loadImage("assets/chess/knightw.png")
  bishopb=loadImage("assets/chess/bishopb.png")
  bishopw=loadImage("assets/chess/bishopw.png")
  queenb=loadImage("assets/chess/queenb.png")
  queenw=loadImage("assets/chess/queenw.png")
  kingb=loadImage("assets/chess/kingb.png")
  kingw=loadImage("assets/chess/kingw.png")

  --chess board
  blockw=width/8

  background('darkgreen')
  for y=0,8 do
    for x=0,8 do
      if (x%2 == 0 and y%2 == 0) or (x%2==1 and y%2==1) then
	fill("white")
	square(x*blockw,y*blockw,blockw)
      end
      --black
      if y<2 then
	fill(80,180)
	circle(x*blockw+blockw/2,y*blockw+blockw/2,blockw)
	if y==1 then
	  image(pawnb,x*blockw+blockw/2,y*blockw+blockw/2,blockw,blockw)
	end
      end
      if y>=6 then
	fill(255,180)
	circle(x*blockw+blockw/2,y*blockw+blockw/2,blockw)
	if y==6 then
	  image(pawnw,x*blockw+blockw/2,y*blockw+blockw/2,blockw,blockw)
	end
      end
    end
  end
  --pieces
  fill("black")
  --rooks
  --black
  image(rookb,blockw/2,blockw/2,blockw,blockw)
  image(rookb,blockw/2+7*blockw,blockw/2,blockw,blockw)
  --white
  image(rookw,blockw/2,blockw*8-blockw/2,blockw,blockw)
  image(rookw,blockw/2+7*blockw,blockw*8-blockw/2,blockw,blockw)
  --knight
  image(knightb,blockw+blockw/2,blockw-blockw/2,blockw)
  image(knightb,6*blockw+blockw/2,blockw-blockw/2,blockw)
  image(knightw,blockw+blockw/2,8*blockw-blockw/2,blockw)
  image(knightw,6*blockw+blockw/2,8*blockw-blockw/2,blockw)
  --bishops
  image(bishopb,2*blockw+blockw/2,blockw-blockw/2,blockw)
  image(bishopb,5*blockw+blockw/2,blockw-blockw/2,blockw)
  image(bishopw,2*blockw+blockw/2,8*blockw-blockw/2,blockw)
  image(bishopw,5*blockw+blockw/2,8*blockw-blockw/2,blockw)
  --queens
  image(queenb,3*blockw+blockw/2,blockw-blockw/2,blockw)
  image(queenw,3*blockw+blockw/2,8*blockw-blockw/2,blockw)
  --kings
  image(kingw,4*blockw+blockw/2,blockw-blockw/2,blockw)
  image(kingw,4*blockw+blockw/2,8*blockw-blockw/2,blockw)

  describe("A checkerboard pattern with the starting position of chess. There are round chess pieces with their icons inscribed, white along the bottom 2 rows and black starting on top.")
end


