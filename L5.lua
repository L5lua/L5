function love.load()
  setup()
  love.math.setRandomSeed(love.timer.getTime())
end
function love.update()
  mouseX, mouseY = love.mouse.getPosition()
end
function love.draw()
  draw()
end

function love.mousepressed(_x,_y, button, istouch, presses )
  mousePressed()
end
function createWindow(_w,_h)
  love.window.setMode(_w,_h) --leaving out optional flags for now
  defaults()
  --environment()
end

function environment()
  background(255,255,255)
end

function defaults()
  -- constants
  CORNER = "CORNER"
  RADIUS = "RADIUS"
  CORNERS = "CORNERS"
  CENTER = "CENTER"
  global_rect_mode = CORNER --also: CORNERS, CENTER
  fillMode="fill"   --also: "line"
  PI=math.pi
  HALF_PI=math.pi/2
  QUARTER_PI=math.pi/4
  TWO_PI=2*math.pi
  PIE="pie"
  OPEN="open"
  CHORD="closed"
  global_stroke_color = {0,0,0}
  width, height = love.graphics.getDimensions()
  mouseX=0
  mouseY=0
end

--drawing functions

function rect(_a,_b,_c,_d)
  if global_rect_mode=="CORNERS" then --x1,y1,x2,y2
    love.graphics.rectangle(fillMode,_a,_b,_c-_a,_d-_b)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.rectangle("line",_a,_b,_c-_a,_d-_b)
    love.graphics.pop()
  elseif global_rect_mode=="CENTER" then --x-w/2,y-h/2,w,h 
    love.graphics.rectangle(fillMode, _a-_c/2,_b-_d/2,_c,_d)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c,_d)
    love.graphics.pop()
  elseif global_rect_mode=="RADIUS" then --x-w/2,y-h/2,r1*2,r2*2
    love.graphics.rectangle(fillMode, _a-_c/2,_b-_d/2,_c*2,_d*2)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c*2,_d*2)
    love.graphics.pop()
  else --CORNER default x,y,w,h
    love.graphics.rectangle(fillMode,_a,_b,_c,_d)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.rectangle("line",_a,_b,_c,_d)
    love.graphics.pop()
  end
end

function square(_a,_b,_c)
  --CORNERS mode doesn't exist for squares
  if global_rect_mode=="CENTER" then --x-w/2,y-h/2,w,h 
    love.graphics.rectangle(fillMode, _a-_c/2,_b-_c/2,_c,_c)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c,_c)
    love.graphics.pop()
  elseif global_rect_mode=="RADIUS" then --x-w/2,y-h/2,r*2,r*2
    love.graphics.rectangle(fillMode, _a-_c/2,_b-_c/2,_c*2,_c*2)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c*2,_c*2)
    love.graphics.pop()
  else --CORNER default x,y,w,h
    love.graphics.rectangle(fillMode,_a,_b,_c,_c)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.rectangle("line",_a,_b,_c,_c)
    love.graphics.pop()
  end

end

function ellipse(_a,_b,_c,_d)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  if global_ellipse_mode=="RADIUS" then
    love.graphics.ellipse(fillMode,_a,_b,_c,_d)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.ellipse("line",_a,_b,_c,_d)
    love.graphics.pop()
  elseif global_ellipse_mode=="CORNER" then
    love.graphics.ellipse(fillMode,_a+_c/2,_b+_d/2,_c/2,_d/2)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.ellipse("line",_a+_c/2,_b+_d/2,_c/2,_d/2)
    love.graphics.pop()
  elseif global_ellipse_mode=="CORNERS" then
    love.graphics.ellipse(fillMode,_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.ellipse("line",_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2)
    love.graphics.pop()
  else --default CENTER x,y,w/2,h/2
    love.graphics.ellipse(fillMode,_a,_b,_c/2,_d/2)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.ellipse("line",_a,_b,_c/2,_d/2)
    love.graphics.pop()
  end
end

function circle(_a,_b,_c)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  love.graphics.ellipse(fillMode,_a,_b,_c/2,_c/2)
  love.graphics.push("all")
    fill(global_stroke_color)
    love.graphics.ellipse("line",_a,_b,_c/2,_c/2)
  love.graphics.pop()
end

function quad(_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) --this is a 4-sided love2d polygon! a quad implies an applied texture
  --for other # of sides, use processing api call createShape
  love.graphics.polygon(fillMode,_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
  love.graphics.push("all")
    fill(global_stroke_color)
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
  love.graphics.pop()
end

function triangle(_x1,_y1,_x2,_y2,_x3,_y3) --this is a 3-sided love2d polygon 
  love.graphics.polygon(fillMode,_x1,_y1,_x2,_y2,_x3,_y3)
  love.graphics.push("all")
    fill(global_stroke_color)
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3)
  love.graphics.pop()
end

--TODO: Implement _h height! Maybe requires scale along y?
--p5 calls arctype paramater "mode"
function arc(_x,_y,_w,_h,_start,_stop,_arctype)
  if _arctype then
    love.graphics.arc(fillMode, _arctype, _x, _y, _w/2, _start, _stop)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.arc("line", _arctype, _x, _y, _w/2, _start, _stop)
    love.graphics.pop()
  else --no specified mode, use PIE default
    love.graphics.arc(fillMode, _x, _y, _w/2, _start, _stop)
    love.graphics.push("all")
      fill(global_stroke_color)
      love.graphics.arc("line", _x, _y, _w/2, _start, _stop)
    love.graphics.pop()
  end
end

function point(_x,_y)
  --Points unaffected by love.graphics.scale - size is always in pixels
  love.graphics.points(_x,_y)
end

function line(_x1,_y1,_x2,_y2)
  love.graphics.line(_x1,_y1,_x2,_y2)
end

function background(_r,_g,_b)
  love.graphics.setBackgroundColor(love.math.colorFromBytes(_r, _g, _b,_a))
end

function fill(_r,_g,_b,_a)
  love.graphics.setColor(love.math.colorFromBytes(_r, _g, _b,_a))
end

function rectMode(_mode)
  global_rect_mode=_mode
end

function ellipseMode(_mode)
  global_ellipse_mode=_mode
end

function noFill()
  fillMode="line" --fill is transparent
end

function strokeWeight(_w)
  love.graphics.setLineWidth(_w)
end

function stroke(_r,_g,_b)
  global_stroke_color={_r,_g,_b}
end

function random(_a,_b)
  if _b then
    return love.math.random()*(_b-_a)+_a
  else
    return love.math.random()*_a
  end
end
