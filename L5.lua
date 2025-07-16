-- Custom love.run() function that doesn't clear screen between frames but does clear matrix transformation
function love.run()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
  
  -- We don't want to clear the screen automatically
  if love.timer then love.timer.step() end
  
  local dt = 0
  
  -- Main loop
    return function()

    -- Process events
    if love.event then
      love.event.pump()
      for name, a,b,c,d,e,f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a or 0
          end
        end
        love.handlers[name](a,b,c,d,e,f)
      end
    end
    
    -- Update dt
    if love.timer then dt = love.timer.step() end
    
    -- Update
    if love.update then love.update(dt) end
    
    -- Draw (without clearing!)
    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      -- DON'T call love.graphics.clear() here!
      if love.draw then love.draw() end
      love.graphics.present()
    end
    
    if love.timer then love.timer.sleep(0.001) end
  end
end

function love.load()
  love.math.setRandomSeed(os.time())
  defaults()
  if setup ~= nil then setup() end
end

function love.update()
  mouseX, mouseY = love.mouse.getPosition()
  deltaTime=love.timer.getDelta()
  key = updateLastKeyPressed()
end

function love.draw()
  frameCount=frameCount+1
  local isPressed = love.mouse.isDown(1)
    
    if isPressed and not wasPressed then
        -- Mouse was just pressed this frame
	if mousePressed ~= nil then mousePressed() end
    end
    
    wasPressed = isPressed

  if draw ~= nil then draw() end
end

function love.mousepressed(_x,_y, button, istouch, presses )
  --if mousePressed ~= nil then mousePressed() end
end

function love.keypressed(key, scancode, isrepeat)
  if keyPressed ~= nil then keyPressed() end
end

function love.keyreleased(key)
  if keyReleased ~= nil then keyReleased() end
end

function love.textinput(_text)
  key = _text
  if keyTyped ~= nil then keyTyped() end
end

------------------- CUSTOM FUNCTIONS -----------------

function size(_w,_h)
  love.window.setMode(_w,_h) --leaving out optional flags for now

  --dependent on window size
  width, height = love.graphics.getDimensions()
  --background(120,120,120)
end

function fullscreen(_bool)
  if _bool then
    love.window.setFullscreen(_bool)
  else
    return love.window.getFullscreen()
  end
end

function environment() 
  --background(255,255,255)
end

function defaults()
  -- constants
  CORNER = "CORNER"
  RADIUS = "RADIUS"
  CORNERS = "CORNERS"
  CENTER = "CENTER"
  RADIANS = "RADIANS"
  DEGREES = "DEGREES"
  PI=math.pi
  HALF_PI=math.pi/2
  QUARTER_PI=math.pi/4
  TWO_PI=2*math.pi
  TAU=TWO_PI
  PIE="pie"
  OPEN="open"
  CHORD="closed"

  -- environment global variables
  frameCount = 0
  drawing = true
  wasPressed = false
  global_degree_mode = RADIANS --also: DEGREES
  global_rect_mode = CORNER --also: CORNERS, CENTER
  global_ellipse_mode = CENTER
  global_image_mode = CORNER
  fillMode="fill"   --also: "line"
  global_stroke_color = {0,0,0}
  mouseX=0
  mouseY=0
  currentTint = {1, 1, 1, 1} -- Default: no tint white
  --lastKeyPressed = nil
  key = nil
  keyIsPressed = false
end

----------------------- EVENTS ----------------------

---------------------- KEYBOARD ---------------------

-- helper function referenced in love.update()
function updateLastKeyPressed()
  local commonKeys = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
                     "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
                     "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
                     "space", "return", "escape", "up", "down", "left", "right",
                     "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt"}

    -- reset keyIsPressed to false initially
    keyIsPressed = false

    -- Check each key and update vars
    for _, k in ipairs(commonKeys) do
      if love.keyboard.isDown(k) then
        key = k
	keyIsPressed = true
        break -- Take the first key found
      end
    end
    
  return key
end

function keyIsDown(_key) 
  return love.keyboard.isDown(_key)
end

------------------------ MOUSE ----------------------

---------------------- TRANSFORM ---------------------

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
  if global_degree_mode == RADIANS then
    love.graphics.rotate(_angle)
  else
    love.graphics.rotate(radians(_angle))
  end
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
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.rectangle("line",_a,_b,_c-_a,_d-_b)
    love.graphics.setColor(r, g, b, a)
  elseif global_rect_mode=="CENTER" then --x-w/2,y-h/2,w,h 
    love.graphics.rectangle(fillMode, _a-_c/2,_b-_d/2,_c,_d)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c,_d)
    love.graphics.setColor(r, g, b, a)
  elseif global_rect_mode=="RADIUS" then --x-w/2,y-h/2,r1*2,r2*2
    love.graphics.rectangle(fillMode, _a-_c/2,_b-_d/2,_c*2,_d*2)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c*2,_d*2)
    love.graphics.setColor(r, g, b, a)
  else --CORNER default x,y,w,h
    love.graphics.rectangle(fillMode,_a,_b,_c,_d)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.rectangle("line",_a,_b,_c,_d)
    love.graphics.setColor(r, g, b, a)
  end
end

function square(_a,_b,_c)
  --CORNERS mode doesn't exist for squares
  if global_rect_mode=="CENTER" then --x-w/2,y-h/2,w,h 
    love.graphics.rectangle(fillMode, _a-_c/2,_b-_c/2,_c,_c)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c,_c)
    love.graphics.setColor(r, g, b, a)
  elseif global_rect_mode=="RADIUS" then --x-w/2,y-h/2,r*2,r*2
    love.graphics.rectangle(fillMode, _a-_c/2,_b-_c/2,_c*2,_c*2)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c*2,_c*2)
    love.graphics.setColor(r, g, b, a)
  else --CORNER default x,y,w,h
    love.graphics.rectangle(fillMode,_a,_b,_c,_c)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.rectangle("line",_a,_b,_c,_c)
    love.graphics.setColor(r, g, b, a)
  end
end

function ellipse(_a,_b,_c,_d)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  if global_ellipse_mode=="RADIUS" then
    love.graphics.ellipse(fillMode,_a,_b,_c,_d)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.ellipse("line",_a,_b,_c,_d)
    love.graphics.setColor(r, g, b, a)
  elseif global_ellipse_mode=="CORNER" then
    love.graphics.ellipse(fillMode,_a+_c/2,_b+_d/2,_c/2,_d/2)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.ellipse("line",_a+_c/2,_b+_d/2,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  elseif global_ellipse_mode=="CORNERS" then
    love.graphics.ellipse(fillMode,_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.ellipse("line",_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2)
    love.graphics.setColor(r, g, b, a)
  else --default CENTER x,y,w/2,h/2
    love.graphics.ellipse(fillMode,_a,_b,_c/2,_d/2)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.ellipse("line",_a,_b,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  end
end

function circle(_a,_b,_c)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  love.graphics.ellipse(fillMode,_a,_b,_c/2,_c/2)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.ellipse("line",_a,_b,_c/2,_c/2)
    love.graphics.setColor(r, g, b, a)
end

function quad(_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) --this is a 4-sided love2d polygon! a quad implies an applied texture
  --for other # of sides, use processing api call createShape
  love.graphics.polygon(fillMode,_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
    love.graphics.setColor(r, g, b, a)
end

function triangle(_x1,_y1,_x2,_y2,_x3,_y3) --this is a 3-sided love2d polygon 
  love.graphics.polygon(fillMode,_x1,_y1,_x2,_y2,_x3,_y3)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3)
    love.graphics.setColor(r, g, b, a)
end

--TODO: Implement _h height! Maybe requires scale along y?
--p5 calls arctype paramater "mode"
function arc(_x,_y,_w,_h,_start,_stop,_arctype)
  if _arctype then
    love.graphics.arc(fillMode, _arctype, _x, _y, _w/2, _start, _stop)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.arc("line", _arctype, _x, _y, _w/2, _start, _stop)
    love.graphics.setColor(r, g, b, a)
  else --no specified mode, use PIE default
    love.graphics.arc(fillMode, _x, _y, _w/2, _start, _stop)
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.arc("line", _x, _y, _w/2, _start, _stop)
    love.graphics.setColor(r, g, b, a)
  end
end

function point(_x,_y)
  --Points unaffected by love.graphics.scale - size is always in pixels
  love.graphics.points(_x,_y)
end

function line(_x1,_y1,_x2,_y2)
  --a line is drawn in the stroke color
    local r, g, b, a = love.graphics.getColor()
    fill(table.unpack(global_stroke_color))
    love.graphics.line(_x1,_y1,_x2,_y2)
    love.graphics.setColor(r, g, b, a)
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
  if _g == nil then
    -- one argument = grayscale
    _r,_g,_b,_a = _r,_r,_r,255
  elseif _b == nil then
    -- two arguments = grayscale, alpha
    _a = _g
    _r,_g,_b = _r,_r,_r
  elseif _a == nil then
    -- three arguments = r,g,b
    _a = 255
  end
  --love.graphics.setColor(love.math.colorFromBytes(_r, _g, _b,_a))
  love.graphics.setColor(_r/255,_g/255,_b/255,_a/255)
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

function stroke(_r,_g,_b,_a)
  if _g == nil then
    -- one argument = grayscale
    _r,_g,_b,_a = _r,_r,_r,255
  elseif _b == nil then
    -- two arguments = grayscale, alpha
    _a = _g
    _r,_g,_b = _r,_r,_r
  elseif _a == nil then
    -- three arguments = r,g,b
    _a = 255
  end
  global_stroke_color={_r,_g,_b,_a}
end

function noStroke()
  global_stroke_color={0,0,0,0}
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

-------------------- TRIGONOMETRY --------------------

function angleMode(_mode)
    if not _mode then
        return global_degree_mode
    elseif _mode == RADIANS or _mode == DEGREES then
        global_degree_mode = _mode
    end
end

function degrees(_angle)
  return math.deg(_angle)
end

function radians(_angle)
  return math.rad(_angle)
end

function sin(_angle)
  if global_degree_mode == RADIANS then
    return math.sin(_angle)
  else
    return math.sin(radians(_angle))
  end
end

function cos(_angle)
  if global_degree_mode == RADIANS then
    return math.cos(_angle)
  else
    return math.cos(radians(_angle))
  end
end

function tan(_angle)
  if global_degree_mode == RADIANS then
    return math.tan(_angle)
  else
    return math.tan(radians(_angle))
  end
end

------------------- SYSTEM ------------------------
function exit()
  os.exit()
end

function windowTitle(_title)
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
