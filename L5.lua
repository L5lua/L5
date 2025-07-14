function love.load()
  love.math.setRandomSeed(os.time())
  defaults()
  if setup ~= nil then setup() end
  love.graphics.setCanvas()
  displayCanvas()
end
function love.update()
  mouseX, mouseY = love.mouse.getPosition()
  deltaTime=love.timer.getDelta()
end
function love.draw()
  love.graphics.setCanvas(canvas)
  frameCount=frameCount+1
  local isPressed = love.mouse.isDown(1)
    
    if isPressed and not wasPressed then
        -- Mouse was just pressed this frame
	if mousePressed ~= nil then mousePressed() end
    end
    
    wasPressed = isPressed

  if draw ~= nil then draw() end
  love.graphics.setCanvas()
  displayCanvas()
end

function displayCanvas()
  love.graphics.clear()
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(canvas,0,0)
end

function love.mousepressed(_x,_y, button, istouch, presses )
  --if mousePressed ~= nil then mousePressed() end
end

function createWindow(_w,_h)
  love.window.setMode(_w,_h) --leaving out optional flags for now

  --dependent on window size
  width, height = love.graphics.getDimensions()
  canvas = love.graphics.newCanvas(width, height)
  love.graphics.setCanvas(canvas)
  background(120,120,120)
end

function environment() 
  --background(255,255,255)
end

function defaults()
  -- constants
  frameCount = 0
  drawing = true
  wasPressed = false
  CORNER = "CORNER"
  RADIUS = "RADIUS"
  CORNERS = "CORNERS"
  CENTER = "CENTER"
  global_rect_mode = CORNER --also: CORNERS, CENTER
  global_ellipse_mode = CENTER
  global_image_mode = CORNER
  fillMode="fill"   --also: "line"
  PI=math.pi
  HALF_PI=math.pi/2
  QUARTER_PI=math.pi/4
  TWO_PI=2*math.pi
  TAU=TWO_PI
  PIE="pie"
  OPEN="open"
  CHORD="closed"
  global_stroke_color = {0,0,0}
  mouseX=0
  mouseY=0
  currentTint = {1, 1, 1, 1} -- Default: no tint white
end

----------------------- TRANSFORM --------------------

function push()
  love.graphics.push()
end

function pop()
  love.graphics.pop()
end

function translate(_x,_y)
  love.graphics.translate(_x,_y )
end

function rotate(_angle)
  love.graphics.rotate(_angle)
end

function scale(_sx,_sy)
  if _sy ~= nil then --2 args, 2 dif scales
    love.graphics.scale(_sx,_sy)
  else --only 1 arg, scale same both directions
    love.graphics.scale(_sx,_sx)
  end
end

-------------------- TIME and DATE -------------------

function millis()
  return love.timer.getTime()
end

function day()
  return tonumber(os.date("%d"))
end

function month()
  return tonumber(os.date("%m"))
end

function year()
  return tonumber(os.date("%Y"))
end

------------------------ SHAPE -----------------------

-------------------- 2D Primitives -------------------

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

function background(_r,_g,_b,_a)

    if _g == nil then
        -- One argument = grayscale
	_r,_g,_b,_a=_r,_r,_r,255
    elseif _b == nil then
	-- two arguments = grayscale, opacity
	_a = _g
	_r,_g,_b=_r,_r,_r
    elseif _a == nil then
	-- three arguments = r,g,b
	_a=255
    else
        -- Four arguments = RGBA (assume 0-255 range)
    end

  love.graphics.clear(_r/255,_g/255,_b/255,_a/255)
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

function imageMode(_mode)
  global_image_mode=_mode
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

-------------------- VERTEX -------------------------

function bezier(x1,y1,x2,y2,x3,y3,x4,y4)
  love.graphics.line(love.math.newBezierCurve({x1,y1,x2,y2,x3,y3,x4,y4}):render())
end

--catmull-rom spline - generated
-- curve(x1,y1,x2,y2,x3,y3,x4,y4)
-- x1,y1: first control point (not drawn)
-- x2,y2: first anchor point (curve starts here)
-- x3,y3: second anchor point (curve ends here)
-- x4,y4: last control point (not drawn)
function curve(x1, y1, x2, y2, x3, y3, x4, y4)
    local points = {}
    local segments = 20 -- Number of line segments to approximate the curve
    
    -- Generate points along the curve
    for i = 0, segments do
        local t = i / segments
        
        -- Catmull-Rom spline formula
        local t2 = t * t
        local t3 = t2 * t
        
        -- Basis functions for Catmull-Rom spline
        local b1 = -0.5 * t3 + t2 - 0.5 * t
        local b2 = 1.5 * t3 - 2.5 * t2 + 1
        local b3 = -1.5 * t3 + 2 * t2 + 0.5 * t
        local b4 = 0.5 * t3 - 0.5 * t2
        
        -- Calculate point coordinates
        local x = b1 * x1 + b2 * x2 + b3 * x3 + b4 * x4
        local y = b1 * y1 + b2 * y2 + b3 * y3 + b4 * y4
        
        table.insert(points, x)
        table.insert(points, y)
    end
    
    -- Draw the curve using love.graphics.line
    if #points >= 4 then
        love.graphics.line(points)
    end
end

--------------------- MATH --------------------------
function random(_a,_b)
  if _b then
    return love.math.random()*(_b-_a)+_a
  else
    return love.math.random()*_a
  end
end

function abs(_a)
  return math.abs(_a)
end

function round(_a)
  return math.floor(_a + 0.5 * (_a >= 0 and 1 or -1))
end

function ceil(_a)
  return math.ceil(_a)
end

function floor(_a)
  return math.floor(_a)
end

function max(...)
  local args={...}
  return math.max(table.unpack(args))
end

function min(...)
  local args={...}
  return math.min(table.unpack(args))
end

function constrain(_val,_min,_max)
  return math.max(_min, math.min(_val,_max));
end

function map(_val, inputMin, inputMax, outputMin, outputMax, withinBounds)
    local mapped = outputMin + (outputMax - outputMin) * ((_val - inputMin) / (inputMax - inputMin))
    
    if withinBounds then
        if outputMin < outputMax then
            mapped = math.max(outputMin, math.min(outputMax, mapped))
        else
            mapped = math.max(outputMax, math.min(outputMin, mapped))
        end
    end
    
    return mapped
end

function dist(x1,y1,x2,y2)
  return ((x2-x1)^2+(y2-y1)^2)^0.5
end

function sin(_a)
  return math.sin(_a)
end

function cos()
  return math.cos(_a)
end

function tan()
  return math.tan(_a)
end

------------------- SYSTEM ------------------------
function exit()
  os.exit()
end

function setTitle(_title)
  love.window.setTitle(_title)
end

function resizeWindow(_w,_h)
  love.resize(_w,_h)
end

function clear()
  love.graphics.clear()
end

function frameRate(_inp)
  if _inp then --change frameRate

  else --get frameRate
    return love.timer.getFPS( )
  end
end

function noLoop()
  love.draw = function() end
  drawing = false
end

function loop()
  love.draw = draw()
  drawing = true
end

function isLooping()
  if drawing then
    return true
  else
    return false
  end
end

function redraw()
  draw()
  noLoop()
end

--------------------- TYPOGRAPHY ---------------------

function text(_msg,_x,_y)
  love.graphics.print(_msg,_x,_y)
end

---------------- LOADING & DISPLAYING ----------------

function loadImage(_filename)
  return love.graphics.newImage(_filename)
end

function image(_img,_x,_y,_w,_h)
  local originalWidth = _img:getWidth()
  local originalHeight = _img:getHeight()

  local xscale = _w and (_w/originalWidth) or 1
  local yscale = _h and (_h/originalHeight) or xscale

  if global_image_mode==CENTER then
    ox=originalWidth/2
    oy=originalHeight/2
  else --TODO: add in CORNERS mode
    ox,oy=0,0
  end

  love.graphics.draw(_img,_x,_y,0,xscale,yscale,ox,oy)
end

function tint(r, g, b, a)
    if r == nil then
        -- No arguments = no tint (white)
        currentTint = {1, 1, 1, 1}
    elseif g == nil then
        -- One argument = grayscale
        local gray = r / 255
        currentTint = {gray, gray, gray, 1}
    elseif a == nil then
        currentTint = {r/255, g/255, b/255, 1}
    else
        -- Four arguments = RGBA (assume 0-255 range)
        currentTint = {r/255, g/255, b/255, a/255}
    end
end

function noTint()
    currentTint = {1, 1, 1, 1}
end

-- Override love.graphics.draw to automatically apply tint
local originalDraw = love.graphics.draw
function love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    -- Store current color
    local prevR, prevG, prevB, prevA = love.graphics.getColor()
    
    -- Apply tint
    love.graphics.setColor(currentTint[1], currentTint[2], currentTint[3], currentTint[4])
    
    -- Call original draw function
    originalDraw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    
    -- Restore previous color
    love.graphics.setColor(prevR, prevG, prevB, prevA)
end

function cursor(_cursor_icon)
  love.mouse.setVisible(true)
  local _cursor_icon = _cursor_icon or "arrow"
  local _cursor = love.mouse.getSystemCursor(_cursor_icon)
  love.mouse.setCursor(_cursor)
end

function noCursor()
  love.mouse.setVisible(false)
end
