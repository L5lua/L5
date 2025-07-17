-- Custom love.run() function with proper double buffering
function love.run()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
  
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
    
    -- Draw with double buffering
    if love.graphics and love.graphics.isActive() then
      love.graphics.origin()
      
      -- Set render target to back buffer
      if backBuffer then
        love.graphics.setCanvas(backBuffer)
      end
      
      -- Only clear if background() was called this frame
      -- Draw current frame
      if love.draw then love.draw() end
      
      -- Reset to screen and draw the back buffer
      love.graphics.setCanvas()
      if backBuffer then
        love.graphics.draw(backBuffer, 0, 0)
      end
      
      love.graphics.present()
    end
    
    if love.timer then 
      if framerate then --user-specified framerate
       love.timer.sleep(1/framerate)
      else --default framerate
       love.timer.sleep(0.001) 
      end
    end
  end
end

function love.load()
  love.window.setVSync(1)
  love.math.setRandomSeed(os.time())
  
  -- Create double buffers
  local w, h = love.graphics.getDimensions()
  backBuffer = love.graphics.newCanvas(w, h)
  frontBuffer = love.graphics.newCanvas(w, h)
  
  -- Clear both buffers initially
  love.graphics.setCanvas(backBuffer)
  love.graphics.clear(0.5, 0.5, 0.5, 1) -- gray background
  love.graphics.setCanvas(frontBuffer)
  love.graphics.clear(0.5, 0.5, 0.5, 1) -- gray background
  love.graphics.setCanvas()
  
  defaults()
  if setup ~= nil then setup() end
end

function love.update(dt)
  mouseX, mouseY = love.mouse.getPosition()
  deltaTime = dt
  key = updateLastKeyPressed()
  
  -- Call user update logic here (more p5.js-like)
  if update ~= nil then update() end
end

function love.draw()
  frameCount = frameCount + 1
  local isPressed = love.mouse.isDown(1)
    
  if isPressed and not wasPressed then
    -- Mouse was just pressed this frame
    if mousePressed ~= nil then mousePressed() end
  end
    
  wasPressed = isPressed

  -- Check for keyboard events in the draw cycle
  if keyWasPressed then
    if keyPressed ~= nil then keyPressed() end
    keyWasPressed = false
  end
  
  if keyWasReleased then
    if keyReleased ~= nil then keyReleased() end
    keyWasReleased = false
  end
  
  if keyWasTyped then
    if keyTyped ~= nil then keyTyped() end
    keyWasTyped = false
  end

  -- Call user draw function
  if draw ~= nil then draw() end
end

function love.mousepressed(_x, _y, button, istouch, presses)
  if mousePressed ~= nil then mousePressed() end
end

function love.keypressed(key, scancode, isrepeat)
  keyWasPressed = true
end

function love.keyreleased(key)
  keyWasReleased = true
end

function love.textinput(_text)
  key = _text
  keyWasTyped = true
end

function love.resize(w, h)
  -- Recreate buffers when window is resized
  if backBuffer then backBuffer:release() end
  if frontBuffer then frontBuffer:release() end
  
  backBuffer = love.graphics.newCanvas(w, h)
  frontBuffer = love.graphics.newCanvas(w, h)
  
  -- Clear new buffers
  love.graphics.setCanvas(backBuffer)
  love.graphics.clear(1, 1, 1, 1)
  love.graphics.setCanvas(frontBuffer)
  love.graphics.clear(1, 1, 1, 1)
  love.graphics.setCanvas()
  
  width, height = w, h
end

------------------- CUSTOM FUNCTIONS -----------------

function size(_w, _h)
  love.window.setMode(_w, _h)
  
  -- Recreate buffers for new size
  if backBuffer then backBuffer:release() end
  if frontBuffer then frontBuffer:release() end
  
  backBuffer = love.graphics.newCanvas(_w, _h)
  frontBuffer = love.graphics.newCanvas(_w, _h)
  
  -- Clear new buffers
  love.graphics.setCanvas(backBuffer)
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setCanvas(frontBuffer)
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setCanvas()
  
  width, height = love.graphics.getDimensions()
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

function toColor(_r,_g,_b,_a)
  if _g == nil then
    -- one argument = grayscale or color name
    if type(_r) == "number" then
      _r,_g,_b,_a = _r,_r,_r,255
    elseif type(_r) == "string" then
      if _r:sub(1, 1) == "#" then --it's a hex color
	_r, _g, _b = hexToRGB(_r)
	_a = 255
      else --it's a html color value
	_r, _g, _b = table.unpack(htmlColors[_r])
	_a = 255
      end
    else
      --ERROR
    end
  elseif _b == nil then
    -- two arguments = grayscale, alpha
    _a = _g
    _r,_g,_b = _r,_r,_r
  elseif _a == nil then
    -- three arguments = r,g,b
    _a = 255
  end
  return {_r/255,_g/255,_b/255,_a/255}
end

function hexToRGB(hex)
    hex = hex:gsub("#", "") -- Remove # if present
    
    -- Check valid length
    if #hex == 3 then
        hex = hex:gsub("(.)", "%1%1") -- Convert 3 to 6-digit
    elseif #hex ~= 6 then
        return nil, "Invalid hex color format. Expected 3 or 6 characters."
    end
    
    -- Extract RGB components
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    
    -- Check if conversion was successful
    if not r or not g or not b then
        return nil, "Invalid hex color format. Contains non-hex characters."
    end
    
    return r, g, b
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
  global_fill_mode="fill"   --also: "line"
  global_stroke_color = {0,0,0}
  mouseX=0
  mouseY=0
  currentTint = {1, 1, 1, 1} -- Default: no tint white
  key = nil
  keyIsPressed = false
  keyWasPressed = false
  keyWasReleased = false
  keyWasTyped = false
  framerate = nil
  backBuffer = nil
  frontBuffer = nil
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
    love.graphics.rectangle(global_fill_mode,_a,_b,_c-_a,_d-_b)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.rectangle("line",_a,_b,_c-_a,_d-_b)
    love.graphics.setColor(r, g, b, a)
  elseif global_rect_mode=="CENTER" then --x-w/2,y-h/2,w,h 
    love.graphics.rectangle(global_fill_mode, _a-_c/2,_b-_d/2,_c,_d)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c,_d)
    love.graphics.setColor(r, g, b, a)
  elseif global_rect_mode=="RADIUS" then --x-w/2,y-h/2,r1*2,r2*2
    love.graphics.rectangle(global_fill_mode, _a-_c/2,_b-_d/2,_c*2,_d*2)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c*2,_d*2)
    love.graphics.setColor(r, g, b, a)
  else --CORNER default x,y,w,h
    love.graphics.rectangle(global_fill_mode,_a,_b,_c,_d)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.rectangle("line",_a,_b,_c,_d)
    love.graphics.setColor(r, g, b, a)
  end
end

function square(_a,_b,_c)
  --CORNERS mode doesn't exist for squares
  if global_rect_mode=="CENTER" then --x-w/2,y-h/2,w,h 
    love.graphics.rectangle(global_fill_mode, _a-_c/2,_b-_c/2,_c,_c)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c,_c)
    love.graphics.setColor(r, g, b, a)
  elseif global_rect_mode=="RADIUS" then --x-w/2,y-h/2,r*2,r*2
    love.graphics.rectangle(global_fill_mode, _a-_c/2,_b-_c/2,_c*2,_c*2)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c*2,_c*2)
    love.graphics.setColor(r, g, b, a)
  else --CORNER default x,y,w,h
    love.graphics.rectangle(global_fill_mode,_a,_b,_c,_c)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.rectangle("line",_a,_b,_c,_c)
    love.graphics.setColor(r, g, b, a)
  end
end

function ellipse(_a,_b,_c,_d)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  if global_ellipse_mode=="RADIUS" then
    love.graphics.ellipse(global_fill_mode,_a,_b,_c,_d)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c,_d)
    love.graphics.setColor(r, g, b, a)
  elseif global_ellipse_mode=="CORNER" then
    love.graphics.ellipse(global_fill_mode,_a+_c/2,_b+_d/2,_c/2,_d/2)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.ellipse("line",_a+_c/2,_b+_d/2,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  elseif global_ellipse_mode=="CORNERS" then
    love.graphics.ellipse(global_fill_mode,_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.ellipse("line",_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2)
    love.graphics.setColor(r, g, b, a)
  else --default CENTER x,y,w/2,h/2
    love.graphics.ellipse(global_fill_mode,_a,_b,_c/2,_d/2)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  end
end

function circle(_a,_b,_c)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  love.graphics.ellipse(global_fill_mode,_a,_b,_c/2,_c/2)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c/2,_c/2)
    love.graphics.setColor(r, g, b, a)
end

function quad(_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) --this is a 4-sided love2d polygon! a quad implies an applied texture
  --for other # of sides, use processing api call createShape
  love.graphics.polygon(global_fill_mode,_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
    love.graphics.setColor(r, g, b, a)
end

function triangle(_x1,_y1,_x2,_y2,_x3,_y3) --this is a 3-sided love2d polygon 
  love.graphics.polygon(global_fill_mode,_x1,_y1,_x2,_y2,_x3,_y3)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3)
    love.graphics.setColor(r, g, b, a)
end

--TODO: Implement _h height! Maybe requires scale along y?
--p5 calls arctype paramater "mode"
function arc(_x,_y,_w,_h,_start,_stop,_arctype)
  if _arctype then
    love.graphics.arc(global_fill_mode, _arctype, _x, _y, _w/2, _start, _stop)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.arc("line", _arctype, _x, _y, _w/2, _start, _stop)
    love.graphics.setColor(r, g, b, a)
  else --no specified mode, use PIE default
    love.graphics.arc(global_fill_mode, _x, _y, _w/2, _start, _stop)
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(global_stroke_color)) 
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
    love.graphics.setColor(table.unpack(global_stroke_color)) 
    love.graphics.line(_x1,_y1,_x2,_y2)
    love.graphics.setColor(r, g, b, a)
end

function background(_r,_g,_b,_a)
  love.graphics.clear(table.unpack(toColor(_r,_g,_b,_a)))
end

function fill(_r,_g,_b,_a)
  love.graphics.setColor(table.unpack(toColor(_r,_g,_b,_a)))
end

----------------------- COLOR ------------------------
htmlColors = {
    ["aliceblue"] = {240, 248, 255},
    ["antiquewhite"] = {250, 235, 215},
    ["aqua"] = {0, 255, 255},
    ["aquamarine"] = {127, 255, 212},
    ["azure"] = {240, 255, 255},
    ["beige"] = {245, 245, 220},
    ["bisque"] = {255, 228, 196},
    ["black"] = {0, 0, 0},
    ["blanchedalmond"] = {255, 235, 205},
    ["blue"] = {0, 0, 255},
    ["blueviolet"] = {138, 43, 226},
    ["brown"] = {165, 42, 42},
    ["burlywood"] = {222, 184, 135},
    ["cadetblue"] = {95, 158, 160},
    ["chartreuse"] = {127, 255, 0},
    ["chocolate"] = {210, 105, 30},
    ["coral"] = {255, 127, 80},
    ["cornflowerblue"] = {100, 149, 237},
    ["cornsilk"] = {255, 248, 220},
    ["crimson"] = {220, 20, 60},
    ["cyan"] = {0, 255, 255},
    ["darkblue"] = {0, 0, 139},
    ["darkcyan"] = {0, 139, 139},
    ["darkgoldenrod"] = {184, 134, 11},
    ["darkgray"] = {169, 169, 169},
    ["darkgreen"] = {0, 100, 0},
    ["darkgrey"] = {169, 169, 169},
    ["darkkhaki"] = {189, 183, 107},
    ["darkmagenta"] = {139, 0, 139},
    ["darkolivegreen"] = {85, 107, 47},
    ["darkorange"] = {255, 140, 0},
    ["darkorchid"] = {153, 50, 204},
    ["darkred"] = {139, 0, 0},
    ["darksalmon"] = {233, 150, 122},
    ["darkseagreen"] = {143, 188, 139},
    ["darkslateblue"] = {72, 61, 139},
    ["darkslategray"] = {47, 79, 79},
    ["darkslategrey"] = {47, 79, 79},
    ["darkturquoise"] = {0, 206, 209},
    ["darkviolet"] = {148, 0, 211},
    ["deeppink"] = {255, 20, 147},
    ["deepskyblue"] = {0, 191, 255},
    ["dimgray"] = {105, 105, 105},
    ["dimgrey"] = {105, 105, 105},
    ["dodgerblue"] = {30, 144, 255},
    ["firebrick"] = {178, 34, 34},
    ["floralwhite"] = {255, 250, 240},
    ["forestgreen"] = {34, 139, 34},
    ["fuchsia"] = {255, 0, 255},
    ["gainsboro"] = {220, 220, 220},
    ["ghostwhite"] = {248, 248, 255},
    ["gold"] = {255, 215, 0},
    ["goldenrod"] = {218, 165, 32},
    ["gray"] = {128, 128, 128},
    ["green"] = {0, 128, 0},
    ["greenyellow"] = {173, 255, 47},
    ["grey"] = {128, 128, 128},
    ["honeydew"] = {240, 255, 240},
    ["hotpink"] = {255, 105, 180},
    ["indianred"] = {205, 92, 92},
    ["indigo"] = {75, 0, 130},
    ["ivory"] = {255, 255, 240},
    ["khaki"] = {240, 230, 140},
    ["lavender"] = {230, 230, 250},
    ["lavenderblush"] = {255, 240, 245},
    ["lawngreen"] = {124, 252, 0},
    ["lemonchiffon"] = {255, 250, 205},
    ["lightblue"] = {173, 216, 230},
    ["lightcoral"] = {240, 128, 128},
    ["lightcyan"] = {224, 255, 255},
    ["lightgoldenrodyellow"] = {250, 250, 210},
    ["lightgray"] = {211, 211, 211},
    ["lightgreen"] = {144, 238, 144},
    ["lightgrey"] = {211, 211, 211},
    ["lightpink"] = {255, 182, 193},
    ["lightsalmon"] = {255, 160, 122},
    ["lightseagreen"] = {32, 178, 170},
    ["lightskyblue"] = {135, 206, 250},
    ["lightslategray"] = {119, 136, 153},
    ["lightslategrey"] = {119, 136, 153},
    ["lightsteelblue"] = {176, 196, 222},
    ["lightyellow"] = {255, 255, 224},
    ["lime"] = {0, 255, 0},
    ["limegreen"] = {50, 205, 50},
    ["linen"] = {250, 240, 230},
    ["magenta"] = {255, 0, 255},
    ["maroon"] = {128, 0, 0},
    ["mediumaquamarine"] = {102, 205, 170},
    ["mediumblue"] = {0, 0, 205},
    ["mediumorchid"] = {186, 85, 211},
    ["mediumpurple"] = {147, 112, 219},
    ["mediumseagreen"] = {60, 179, 113},
    ["mediumslateblue"] = {123, 104, 238},
    ["mediumspringgreen"] = {0, 250, 154},
    ["mediumturquoise"] = {72, 209, 204},
    ["mediumvioletred"] = {199, 21, 133},
    ["midnightblue"] = {25, 25, 112},
    ["mintcream"] = {245, 255, 250},
    ["mistyrose"] = {255, 228, 225},
    ["moccasin"] = {255, 228, 181},
    ["navajowhite"] = {255, 222, 173},
    ["navy"] = {0, 0, 128},
    ["oldlace"] = {253, 245, 230},
    ["olive"] = {128, 128, 0},
    ["olivedrab"] = {107, 142, 35},
    ["orange"] = {255, 165, 0},
    ["orangered"] = {255, 69, 0},
    ["orchid"] = {218, 112, 214},
    ["palegoldenrod"] = {238, 232, 170},
    ["palegreen"] = {152, 251, 152},
    ["paleturquoise"] = {175, 238, 238},
    ["palevioletred"] = {219, 112, 147},
    ["papayawhip"] = {255, 239, 213},
    ["peachpuff"] = {255, 218, 185},
    ["peru"] = {205, 133, 63},
    ["pink"] = {255, 192, 203},
    ["plum"] = {221, 160, 221},
    ["powderblue"] = {176, 224, 230},
    ["purple"] = {128, 0, 128},
    ["rebeccapurple"] = {102, 51, 153},
    ["red"] = {255, 0, 0},
    ["rosybrown"] = {188, 143, 143},
    ["royalblue"] = {65, 105, 225},
    ["saddlebrown"] = {139, 69, 19},
    ["salmon"] = {250, 128, 114},
    ["sandybrown"] = {244, 164, 96},
    ["seagreen"] = {46, 139, 87},
    ["seashell"] = {255, 245, 238},
    ["sienna"] = {160, 82, 45},
    ["silver"] = {192, 192, 192},
    ["skyblue"] = {135, 206, 235},
    ["slateblue"] = {106, 90, 205},
    ["slategray"] = {112, 128, 144},
    ["slategrey"] = {112, 128, 144},
    ["snow"] = {255, 250, 250},
    ["springgreen"] = {0, 255, 127},
    ["steelblue"] = {70, 130, 180},
    ["tan"] = {210, 180, 140},
    ["teal"] = {0, 128, 128},
    ["thistle"] = {216, 191, 216},
    ["tomato"] = {255, 99, 71},
    ["turquoise"] = {64, 224, 208},
    ["violet"] = {238, 130, 238},
    ["wheat"] = {245, 222, 179},
    ["white"] = {255, 255, 255},
    ["whitesmoke"] = {245, 245, 245},
    ["yellow"] = {255, 255, 0},
    ["yellowgreen"] = {154, 205, 50}
}

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
  global_fill_mode="line" --fill is transparent
end

function strokeWeight(_w)
  love.graphics.setLineWidth(_w)
end

function stroke(_r,_g,_b,_a)
  global_stroke_color = toColor(_r,_g,_b,_a)
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
    framerate = _inp
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
