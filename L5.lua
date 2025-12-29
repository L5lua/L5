-- L5 0.1.3 (c) Lee Tusman and Contributors GNU LGPL2.1
VERSION = '0.1.3'

-- Override love.run() - adds double buffering and custom events
function love.run()
  defaults()
  define_env_globals()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end
  if love.timer then love.timer.step() end
  local dt = 0
  local setupComplete = false
  
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
        
        -- Handle mouse events - store them for drawing phase
        if name == "mousepressed" then
          -- a = x, b = y, c = button, d = istouch, e = presses
          L5_env.pendingMouseClicked = {x = a, y = b, button = c}
        elseif name == "mousereleased" then
          -- a = x, b = y, c = button, d = istouch, e = presses
          L5_env.pendingMouseReleased = {x = a, y = b, button = c}
        end
        
        -- Handle other events through the default handlers
        if love.handlers[name] then
          love.handlers[name](a,b,c,d,e,f)
        end
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
      if L5_env.backBuffer then
        love.graphics.setCanvas(L5_env.backBuffer)
      end
      
      -- Only clear if background() was called this frame
      if L5_env.clearscreen then
        -- background() already cleared with the right color
        L5_env.clearscreen = false
      end
      
      -- Draw current frame
      -- Run setup() once in the drawing context
      if not setupComplete and setup then
        setup()
        setupComplete = true
      else
        if love.draw then love.draw() end
      end
      
	-- Reset to screen and draw the back buffer
	love.graphics.setCanvas()
if L5_env.backBuffer then
  -- Save current color
  local r, g, b, a = love.graphics.getColor()
  
  -- Set to white (no tint) when drawing the canvas to screen
  love.graphics.setColor(1, 1, 1, 1)
  
  if L5_env.filterOn then
    love.graphics.setShader(L5_env.filter)
  end

  love.graphics.draw(L5_env.backBuffer, 0, 0)
  
  if L5_env.filterOn then
    love.graphics.setShader()
    L5_env.filterOn = false
  end
  
  -- Restore color (after drawing the canvas)
  love.graphics.setColor(r, g, b, a)

  love.graphics.present()
end
    
      if love.timer then
	if L5_env.framerate then --user-specified framerate
	  love.timer.sleep(1/L5_env.framerate)
	else --default framerate
	  love.timer.sleep(0.001)
	end
      end
    end
  end
end

function love.load()
  love.window.setVSync(1)
  love.math.setRandomSeed(os.time())

  displayWidth, displayHeight = love.window.getDesktopDimensions()

  -- create default-size buffers. will be recreated again if size() or fullscreen(true) called
  local w, h = love.graphics.getDimensions()

  -- Create double buffers
  L5_env.backBuffer = love.graphics.newCanvas(w, h) 
  L5_env.frontBuffer = love.graphics.newCanvas(w, h) 

  -- Clear both buffers initially
  love.graphics.setCanvas(L5_env.backBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1) -- gray background
  love.graphics.setCanvas(L5_env.frontBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1) -- gray background
  love.graphics.setCanvas()

  initShaderDefaults()

  stroke(0)
  fill(255)
end

function love.update(dt)
  mouseX, mouseY = love.mouse.getPosition()
  movedX=mouseX-pmouseX
  movedY=mouseY-pmouseY
  deltaTime = dt * 1000
  key = updateLastKeyPressed()

  -- Update looping videos
  -- Note: Videos with audio tracks may experience sync issues when looping
-- This is a LÖVE limitation with video/audio stream synchronization
   if L5_env.videos then
    for _, v in ipairs(L5_env.videos) do
      if v._shouldLoop and not v._manuallyPaused and not v._video:isPlaying() then
        v._video:rewind()
        v._video:play()
      end
    end
  end

  -- Optional update (not typically Processing-like but available)
  if update ~= nil then update() end
end

function love.draw()
  -- checking user events happens regardless of whether the user draw() function is currently looping 
  local isPressed = love.mouse.isDown(1) or love.mouse.isDown(2) or love.mouse.isDown(3)

  if isPressed and not L5_env.wasPressed then 
    -- Mouse was just pressed this frame
    if mousePressed ~= nil then mousePressed() end
    mouseIsPressed = true
  elseif not isPressed and L5_env.wasPressed then
    -- Mouse was just released this frame
    if mouseReleased ~= nil then mouseReleased() end
    if mouseClicked ~= nil then mouseClicked() end  -- Run immediately after mouseReleased
    mouseIsPressed = false
  elseif isPressed then
    -- Still pressed - only call mouseDragged if mouse actually moved
    if L5_env.mouseWasMoved then
      if mouseDragged ~= nil then mouseDragged() end
      L5_env.mouseWasMoved = false  -- Clear the flag
    end
    mouseIsPressed = true  
  else
    mouseIsPressed = false
  end

  L5_env.wasPressed = isPressed

  -- Check for keyboard events in the draw cycle
  if L5_env.keyWasPressed then
    if keyPressed ~= nil then keyPressed() end
    L5_env.keyWasPressed = false
  end

  if L5_env.keyWasReleased then
    if keyReleased ~= nil then keyReleased() end
    L5_env.keyWasReleased = false
  end

  if L5_env.keyWasTyped then
    local savedKey = key
    key = L5_env.typedKey  -- Temporarily use the typed character
    if keyTyped ~= nil then keyTyped() end
    key = savedKey  -- Restore
    L5_env.keyWasTyped = false
    L5_env.typedKey = nil
  end

  -- Check for mouse events in draw cycle
  -- Only call mouseMoved if mouse button is NOT pressed
  if L5_env.mouseWasMoved and not isPressed then  
    if mouseMoved ~= nil then mouseMoved() end
    L5_env.mouseWasMoved = false    
  elseif L5_env.mouseWasMoved and isPressed then
    -- Clear the flag even if we don't call mouseMoved
    -- (mouseDragged already handled above)
    L5_env.mouseWasMoved = false
  end
  
  if L5_env.wheelWasMoved then
    if mouseWheel ~= nil then 
      mouseWheel(L5_env.wheelY or 0) 
    end
    L5_env.wheelWasMoved = false
    L5_env.wheelX = nil
    L5_env.wheelY = nil
  end

  -- only run if user draw() function is looping
  if L5_env.drawing then
    frameCount = frameCount + 1

    -- Reset transformation matrix to identity at start of each frame
    love.graphics.origin()
    love.graphics.push()

    -- Call user draw function
    if draw ~= nil then draw() end

    pmouseX, pmouseY = mouseX,mouseY

    love.graphics.pop()
  end
end

function love.mousepressed(_x, _y, button, istouch, presses)
  --turned off so as not to duplicate event handling running twice
  --if mousePressed ~= nil then mousePressed() end
  if button==1 then
    mouseButton=LEFT
  elseif button==2 then
    mouseButton=RIGHT
  elseif button==3 then
    mouseButton=CENTER
  end
end

function love.mousereleased( x, y, button, istouch, presses )
  --if mouseClicked ~= nil then mouseClicked() end
  --if focused and mouseReleased ~= nil then mouseReleased() end
end

function love.wheelmoved(_x,_y)
  L5_env.wheelWasMoved = true
  L5_env.wheelX = _x
  L5_env.wheelY = _y
  return _x, _y
end

function love.mousemoved(x,y,dx,dy,istouch)
  L5_env.mouseWasMoved = true
end

function love.keypressed(k, scancode, isrepeat)
  -- Add key to pressed keys table
  L5_env.pressedKeys[k] = true
  
  key = k
  keyCode = love.keyboard.getScancodeFromKey(k)
  L5_env.keyWasPressed = true
  keyIsPressed = true
end

function love.keyreleased(k)
  -- Remove key from pressed keys table
  L5_env.pressedKeys[k] = nil
  
  key = k
  keyCode = love.keyboard.getScancodeFromKey(k)
  L5_env.keyWasReleased = true
  
  -- Only set keyIsPressed to false if no keys are pressed
  local anyKeyPressed = false
  for _ in pairs(L5_env.pressedKeys) do
    anyKeyPressed = true
    break
  end
  keyIsPressed = anyKeyPressed
end

function love.textinput(_text)
  key = _text
  L5_env.typedKey = _text
  L5_env.keyWasTyped = true 
end

function love.resize(w, h)
  -- Recreate buffers when window is resized at density-scaled resolution
  if L5_env.backBuffer then L5_env.backBuffer:release() end 
  if L5_env.frontBuffer then L5_env.frontBuffer:release() end 
  
  L5_env.backBuffer = love.graphics.newCanvas(w, h) 
  L5_env.frontBuffer = love.graphics.newCanvas(w, h ) 
  
  -- Clear new buffers and apply scaling
  love.graphics.setCanvas(L5_env.backBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  
  love.graphics.setCanvas(L5_env.frontBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  
  love.graphics.setCanvas(L5_env.backBuffer)
  
  -- Update global width/height to logical size
  width, height = w, h
  
  -- Call user's windowResized function if it exists
  if windowResized then
    windowResized()
  end
end

function love.focus(_focused)
    focused = _focused
end

------------------- CUSTOM FUNCTIONS -----------------

function size(_w, _h)
  -- must clear canvas before setMode
  love.graphics.setCanvas()

  love.window.setMode(_w, _h)

  -- Recreate buffers for new size
  if L5_env.backBuffer then L5_env.backBuffer:release() end 
  if L5_env.frontBuffer then L5_env.frontBuffer:release() end 

  L5_env.backBuffer = love.graphics.newCanvas(_w, _h) 
  L5_env.frontBuffer = love.graphics.newCanvas(_w, _h) 

  -- Clear new buffers
  love.graphics.setCanvas(L5_env.backBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setCanvas(L5_env.frontBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1)

  -- Set back to back buffer for continued drawing
  love.graphics.setCanvas(L5_env.backBuffer)

  width, height = love.graphics.getDimensions()
end

function fullscreen(display)
  display = display or 1
  
  love.graphics.setCanvas()
  
  local displays = love.window.getDisplayCount()
  if display > displays then
    display = 1
  end
  
  -- Get dimensions for the specified display
  local w, h = love.window.getDesktopDimensions(display)
  
  -- First, create a windowed mode on that display
  love.window.setMode(w, h, {fullscreen = false})
  
  -- Position the window on the target display
  local xPos = 0
  for i = 1, display - 1 do
    local dw, _ = love.window.getDesktopDimensions(i)
    xPos = xPos + dw
  end
  love.window.setPosition(xPos, 0)
  
  -- Small delay for Windows to process window positioning
  if love.timer then love.timer.sleep(0.1) end
  
  -- Now go fullscreen
  local success, err = pcall(function()
    love.window.setFullscreen(true, "desktop")
  end)
  
  if not success then
    print("Fullscreen error:", err)
    return
  end
  
  -- Release old canvases
  if L5_env.backBuffer then 
    pcall(function() L5_env.backBuffer:release() end)
  end 
  if L5_env.frontBuffer then 
    pcall(function() L5_env.frontBuffer:release() end)
  end 
  
  -- Create new canvases
  L5_env.backBuffer = love.graphics.newCanvas(w, h) 
  L5_env.frontBuffer = love.graphics.newCanvas(w, h) 
  
  love.graphics.setCanvas(L5_env.backBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setCanvas(L5_env.frontBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  
  love.graphics.setCanvas(L5_env.backBuffer)
  width, height = love.graphics.getDimensions()  

  if windowResized then
    windowResized()
  end
end

function toColor(_a, _b, _c, _d)
  -- If _a is a table, return it (assuming it's already in RGBA format)
  if type(_a) == "table" and _b == nil and #_a == 4 then
    return _a
  end

  local r, g, b, a
  
  -- Handle different argument patterns
  if _b == nil then
    -- One argument = grayscale or color name
    if type(_a) == "number" then
      if L5_env.color_mode == RGB then
        r, g, b, a = _a, _a, _a, L5_env.color_max[4]
      elseif L5_env.color_mode == HSB then
        -- Grayscale in HSB: hue=0, saturation=0, brightness=value
        r, g, b = HSVtoRGB(0, 0, _a / L5_env.color_max[3])
        r, g, b = r * L5_env.color_max[1], g * L5_env.color_max[2], b * L5_env.color_max[3]
        a = L5_env.color_max[4]
      elseif L5_env.color_mode == HSL then
        -- Grayscale in HSL: hue=0, saturation=0, lightness=value
        r, g, b = HSLtoRGB(0, 0, _a / L5_env.color_max[3])
        r, g, b = r * L5_env.color_max[1], g * L5_env.color_max[2], b * L5_env.color_max[3]
        a = L5_env.color_max[4]
      end
    elseif type(_a) == "string" then
      if _a:sub(1, 1) == "#" then -- Hex color
        r, g, b = hexToRGB(_a)
        a = L5_env.color_max[4]
      else -- HTML color name
        if htmlColors[_a] then
          r, g, b = unpack(htmlColors[_a])
          a = L5_env.color_max[4]
        else
          error("Color '" .. _a .. "' not found in htmlColors table")
        end
      end
    else
      error("Invalid color argument")
    end
  elseif _c == nil then
    -- Two arguments = grayscale with alpha
    if L5_env.color_mode == RGB then
      r, g, b, a = _a, _a, _a, _b
    elseif L5_env.color_mode == HSB then
      r, g, b = HSVtoRGB(0, 0, _a / L5_env.color_max[3])
      r, g, b = r * L5_env.color_max[1], g * L5_env.color_max[2], b * L5_env.color_max[3]
      a = _b
    elseif L5_env.color_mode == HSL then
      r, g, b = HSLtoRGB(0, 0, _a / L5_env.color_max[3])
      r, g, b = r * L5_env.color_max[1], g * L5_env.color_max[2], b * L5_env.color_max[3]
      a = _b
    end
  elseif _d == nil then
    -- Three arguments = color components without alpha
    if L5_env.color_mode == RGB then
      r, g, b, a = _a, _b, _c, L5_env.color_max[4]
    elseif L5_env.color_mode == HSB then
      r, g, b = HSVtoRGB(_a / L5_env.color_max[1], _b / L5_env.color_max[2], _c / L5_env.color_max[3])
      r, g, b = r * L5_env.color_max[1], g * L5_env.color_max[2], b * L5_env.color_max[3]
      a = L5_env.color_max[4]
    elseif L5_env.color_mode == HSL then
      r, g, b = HSLtoRGB(_a / L5_env.color_max[1], _b / L5_env.color_max[2], _c / L5_env.color_max[3])
      r, g, b = r * L5_env.color_max[1], g * L5_env.color_max[2], b * L5_env.color_max[3]
      a = L5_env.color_max[4]
    end
  else
    -- Four arguments = color components with alpha
    if L5_env.color_mode == RGB then
      r, g, b, a = _a, _b, _c, _d
    elseif L5_env.color_mode == HSB then
      r, g, b = HSVtoRGB(_a / L5_env.color_max[1], _b / L5_env.color_max[2], _c / L5_env.color_max[3])
      r, g, b = r * L5_env.color_max[1], g * L5_env.color_max[2], b * L5_env.color_max[3]
      a = _d
    elseif L5_env.color_mode == HSL then
      r, g, b = HSLtoRGB(_a / L5_env.color_max[1], _b / L5_env.color_max[2], _c / L5_env.color_max[3])
      r, g, b = r * L5_env.color_max[1], g * L5_env.color_max[2], b * L5_env.color_max[3]
      a = _d
    end
  end

  -- Return normalized RGBA values (0-1 range)
  return {r/L5_env.color_max[1], g/L5_env.color_max[2], b/L5_env.color_max[3], a/L5_env.color_max[4]}
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

function HSVtoRGB(h, s, v) 
    if s <= 0 then 
        return v, v, v
    end
    h = h * 6
    local c = v * s
    local x = c * (1 - math.abs((h % 2) - 1))
    local m = v - c
    local r, g, b = 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r + m, g + m, b + m
end

function HSLtoRGB(h, s, l)
    if s <= 0 then 
        return l, l, l
    end
    h = h * 6
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = c * (1 - math.abs((h % 2) - 1))
    local m = l - c / 2
    local r, g, b = 0, 0, 0
    if h < 1 then
        r, g, b = c, x, 0
    elseif h < 2 then
        r, g, b = x, c, 0
    elseif h < 3 then
        r, g, b = 0, c, x
    elseif h < 4 then
        r, g, b = 0, x, c
    elseif h < 5 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end
    return r + m, g + m, b + m
end

function RGBtoHSL(r, g, b)
  -- Normalize RGB values to 0-1 range
  r = r / 255
  g = g / 255
  b = b / 255
  
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s, l
  
  -- Calculate lightness
  l = (max + min) / 2
  
  if max == min then
    -- Achromatic (no color)
    h = 0
    s = 0
  else
    local d = max - min
    
    -- Calculate saturation
    if l > 0.5 then
      s = d / (2 - max - min)
    else
      s = d / (max + min)
    end
    
    -- Calculate hue
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    elseif max == b then
      h = (r - g) / d + 4
    end
    
    h = h / 6
  end
  
  -- Convert to 0-360 for hue, 0-100 for saturation and lightness
  return h * L5_env.color_max[1], s * L5_env.color_max[2], l * L5_env.color_max[3]
end

function save(filename)
    love.graphics.captureScreenshot(function(imageData)
        -- Generate filename
        local finalFilename
        
        if filename then
            -- Check if filename ends with .png
            if filename:match("%.png$") then
                finalFilename = filename
            else
                -- Add .png extension
                finalFilename = filename .. ".png"
            end
        else
            -- Use default timestamp-based name
            local timestamp = os.date("%Y%m%d_%H%M%S")
            finalFilename = "screenshot_" .. timestamp .. ".png"
        end
        
        -- Encode to PNG
        local pngData = imageData:encode("png")
        
        -- Try to write to current directory first
        local programDir = love.filesystem.getSource()
        local targetPath = programDir .. "/" .. finalFilename
        
        local file = io.open(targetPath, "wb")
        if file then
            file:write(pngData:getString())
            file:close()
            print("Screenshot saved to: " .. targetPath)
        else
            -- Fallback: use Love2d's save directory
            print("Warning: Could not write to current directory, using save directory instead")
            local success = love.filesystem.write(finalFilename, pngData)
            
            if success then
                local saveDir = love.filesystem.getSaveDirectory()
                print("Screenshot saved to: " .. saveDir .. "/" .. finalFilename)
            else
                print("Error: Could not save screenshot")
            end
        end
    end)
end

function describe(sceneDescription)
 if not L5_env.described then
    print("CANVAS_DESCRIPTION: " .. sceneDescription)
    io.flush() -- Ensure immediate output for screen readers
    L5_env.described = true
    end
end

function defaults()
  -- constants
  -- shapes
  CORNER = "CORNER"
  RADIUS = "RADIUS"
  CORNERS = "CORNERS"
  CENTER = "CENTER"
  RADIANS = "RADIANS"
  DEGREES = "DEGREES"
  ROUND = "smooth"
  SQUARE = "rough"
  PROJECT = "project"
  MITER = "miter"
  BEVEL = "bevel"
  NONE = "none"
  -- typography
  LEFT = "left"
  RIGHT = "right"
  CENTER = "center"
  TOP = "top"
  BOTTOM = "bottom"
  BASELINE = "baseline"
  WORD = "word"
  CHAR = "char"
  -- color
  RGB = "rgb"
  HSB = "hsb"
  HSL = "hsl"
  -- math
  PI = math.pi
  HALF_PI = math.pi/2
  QUARTER_PI=math.pi/4
  TWO_PI = 2 * math.pi
  TAU = TWO_PI
  PIE = "pie"
  OPEN = "open"
  CHORD = "closed"
  -- filters (shaders)
  GRAY = "gray"
  THRESHOLD = "threshold"
  INVERT = "invert"
  POSTERIZE = "posterize"
  BLUR = "blur"
  ERODE = "erode"
  DILATE = "dilate"
  -- for applying texture wrapping
  NORMAL = "NORMAL"
  IMAGE = "IMAGE"
  CLAMP = "clamp"
  REPEAT = "repeat"
  -- blend modes
  BLEND = "blend"
  ADD = "add"
  MULTIPLY = "multiply"
  SCREEN = "screen"
  LIGHTEST = "lightest"
  DARKEST = "darkest"
  REPLACE = "replace"
  -- system cursors
  ARROW = "arrow"
  IBEAM = "ibeam"
  WAIT = "wait"
  WAITARROW = "waitarrow"
  CROSSHAIR = "crosshair"
  SIZENWSE = "sizenwse"
  SIZENESW = "sizenesw"
  SIZEWE = "sizewe"
  SIZENS = "sizens"
  SIZEALL = "sizeall"
  NO = "no"
  HAND = "hand"

  -- global user vars - can be read by user but shouldn't be altered by user
  key = "" --default, overriden with key presses detected in love.update(dt)
  width = 800 --default, overridden with size() or fullscreen()
  height = 600 --ditto
  frameCount = 0
  mouseIsPressed = false
  mouseX=0
  mouseY=0
  keyIsPressed = false
  pmouseX,pmouseY,movedX,movedY=0,0
  mouseButton = nil
  focused = true
  pixels = {}
end

-- environment global variables not user-facing
function define_env_globals()
  L5_env = L5_env or {} -- Initialize L5_env if it doesn't exist
  L5_env.drawing = true
  -- drawing mode state
  L5_env.degree_mode = RADIANS --also: DEGREES
  L5_env.rect_mode = CORNER --also: CORNERS, CENTER, RADIUS
  L5_env.ellipse_mode = CENTER --also: CORNER, CORNERS, RADIUS
  L5_env.image_mode = CORNER --also: CENTER, CORNERS
  -- global color state 
  L5_env.fill_mode="fill"   --also: "line"
  L5_env.stroke_color = {0,0,0}
  L5_env.currentTint = {1, 1, 1, 1} -- Default: no tint white
  L5_env.color_max = {255,255,255,255}
  L5_env.color_mode = RGB --also: HSB, HSL
  -- global key state
  L5_env.pressedKeys = {}
  L5_env.keyWasPressed = false
  L5_env.keyWasReleased = false
  L5_env.keyWasTyped = false
  L5_env.typedKey = nil
  -- mouse state
  L5_env.mouseWasMoved = false
  L5_env.wasPressed = false
  L5_env.wheelWasMoved = false
  L5_env.wheelX = nil
  L5_env.wheelY = nil
  L5_env.pendingMouseClicked = nil
  L5_env.pendingMouseReleased = nil
  -- screen buffer state
  L5_env.framerate = nil
  L5_env.backBuffer = nil
  L5_env.frontBuffer = nil
  L5_env.clearscreen = false
  L5_env.described = false
  -- global video tracking for looping
  L5_env.videos = {}
  -- global font state
  L5_env.fontPaths = {}
  L5_env.currentFontPath = nil
  L5_env.currentFontSize = 12
  L5_env.textAlignX = LEFT
  L5_env.textAlignY = BASELINE
  L5_env.textWrap = WORD
  -- filters (shaders)
  L5_env.filterOn = false
  L5_env.filter = nil
  -- pixel array
  L5_env.pixels = {}
  L5_env.imageData = nil
  L5_env.pixelsLoaded = false
  -- custom shape drawing 
  L5_env.vertices = {}
  -- custom texture mesh
  L5_env.currentTexture = nil
  L5_env.useTexture = false
  L5_env.textureMode=IMAGE -- NORMAL or IMAGE
  L5_env.textureWrap=CLAMP -- wrap mode CLAMP or REPEAT
end
------------------ INIT SHADERS ---------------------
-- initialize shader default values
function initShaderDefaults()
    -- Set default values for threshold shader
    L5_filter.threshold:send("soft", 0.5)
    L5_filter.threshold:send("threshold", 0.5)
    
    -- Set default value for posterize
    L5_filter.posterize:send("levels", 4.0)
    -- Set default values for blur
    L5_filter.blur:send("blurSize", 2.0)
    L5_filter.blur:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    
    -- Set default values for erode
    L5_filter.erode:send("strength", 0.5)
    L5_filter.erode:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    
    -- Set default values for dilate
    L5_filter.dilate:send("strength", 1.0)
    L5_filter.dilate:send("threshold", 0.1)
    L5_filter.dilate:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
end

----------------------- INPUT -----------------------

function loadStrings(_file)
  local lines = {} 
  for line in love.filesystem.lines(_file) do 
    table.insert(lines, line)
  end
  return lines
end

function loadTable(_file, _header)
  local extension = _file:match("%.([^%.]+)$")
  
  if extension == "csv" or extension == "tsv" then
    local separator = (extension == "csv") and "," or "\t"
    local pattern = (extension == "csv") and "[^,]+" or "[^\t]+"
    
    local function splitLine(line)
      local values = {}
      for value in line:gmatch(pattern) do
        if     tonumber(value)  then  table.insert(values, tonumber(value))
        elseif value == "true"  then  table.insert(values, true)
        elseif value == "false" then  table.insert(values, false)
        else                          table.insert(values, value)
        end
      end
      return values
    end
    
    local function loadDelimitedFile(filename)
      local data = {}
      local headers = {}
      local first_line = true
      
      for line in love.filesystem.lines(filename) do
        local row = splitLine(line)
        
        if _header == "header" and first_line then
          for value in line:gmatch(pattern) do
            table.insert(headers, value)
          end
          first_line = false
        else
          if _header == "header" then
            local record = {}
            for i, value in ipairs(row) do
              if headers[i] then
                record[headers[i]] = value
              end
            end
            table.insert(data, record)
          else
            table.insert(data, row)
          end
        end
      end
      
      -- If no headers were loaded, create numbered column identifiers
      if #headers == 0 and #data > 0 then
        for i = 1, #data[1] do
          table.insert(headers, i)
        end
      end
      
      data.columns = headers
      return data
    end
    
    return loadDelimitedFile(_file)
    
  elseif extension == "lua" then
    local chunk = love.filesystem.load(_file)
    if chunk then
      return chunk()
    else
      error("Could not load Lua file: " .. _file)
    end
  else
    error("Unsupported file type: " .. (extension or "no extension") .. " for file: " .. _file)
  end
end

function saveStrings(data, filename)
  local lines = {}
  for i, value in ipairs(data) do
    table.insert(lines, tostring(value))
  end
  local content = table.concat(lines, "\n")
  
  -- Use io.open to write directly to current directory
  local file = io.open(filename, "w")
  if file then
    file:write(content)
    file:close()
    return true
  else
    print("Error: Could not open file for writing: " .. filename)
    return false
  end
end

function saveTable(data, filename, format)
  -- Auto-detect format from filename if not specified
  if not format then
    local extension = filename:match("%.([^%.]+)$")
    format = extension or "lua"
  end
  
  if format == "lua" then
    -- Save as Lua file with return
    local function serializeValue(val)
      if type(val) == "string" then
        return string.format("%q", val)
      elseif type(val) == "number" or type(val) == "boolean" then
        return tostring(val)
      elseif val == nil then
        return "nil"
      else
        return tostring(val)
      end
    end
    
    local function serializeTable(tbl, indent)
      indent = indent or ""
      local lines = {}
      table.insert(lines, "{")
      
      for i, value in ipairs(tbl) do
        if type(value) == "table" then
          table.insert(lines, indent .. "  " .. serializeTable(value, indent .. "  ") .. ",")
        else
          table.insert(lines, indent .. "  " .. serializeValue(value) .. ",")
        end
      end
      
      -- Handle named keys
      for key, value in pairs(tbl) do
        if type(key) ~= "number" or key > #tbl then
          local keyStr = type(key) == "string" and key or "[" .. serializeValue(key) .. "]"
          if type(value) == "table" then
            table.insert(lines, indent .. "  " .. keyStr .. " = " .. serializeTable(value, indent .. "  ") .. ",")
          else
            table.insert(lines, indent .. "  " .. keyStr .. " = " .. serializeValue(value) .. ",")
          end
        end
      end
      
      table.insert(lines, indent .. "}")
      return table.concat(lines, "\n")
    end
    
    local content = "return " .. serializeTable(data)
    
    local file = io.open(filename, "w")
    if file then
      file:write(content)
      file:close()
      return true
    end
    
  elseif format == "csv" or format == "tsv" then
    local separator = (format == "csv") and "," or "\t"
    local lines = {}
    
    -- Check if data is a single record (has named keys but no array elements)
    local isSingleRecord = (#data == 0)
    for k, v in pairs(data) do
      if type(k) == "string" then
        isSingleRecord = true
        break
      end
    end
    
    -- Convert single record to array of one record
    local records = data
    if isSingleRecord and #data == 0 then
      records = {data}
    end

    -- Get headers from first row if it's a table with named keys
    local headers = {}
    if #records > 0 and type(records[1]) == "table" then  -- Fixed: use records
      for key, _ in pairs(records[1]) do                   -- Fixed: use records
        if type(key) == "string" then
          table.insert(headers, key)
        end
      end
      
      if #headers > 0 then
        -- Add header row
        table.insert(lines, table.concat(headers, separator))
        
        -- Add data rows using headers
        for i, row in ipairs(records) do  -- Fixed: use records
          local values = {}
          for _, header in ipairs(headers) do
            table.insert(values, tostring(row[header] or ""))
          end
          table.insert(lines, table.concat(values, separator))
        end
      else
        -- Array-style table, just use indices
        for i, row in ipairs(records) do  -- Fixed: use records
          if type(row) == "table" then
            local values = {}
            for _, value in ipairs(row) do
              table.insert(values, tostring(value))
            end
            table.insert(lines, table.concat(values, separator))
          else
            table.insert(lines, tostring(row))
          end
        end
      end
    else
      -- Simple array
      for i, value in ipairs(records) do  -- Fixed: use records
        table.insert(lines, tostring(value))
      end
    end
    
    local content = table.concat(lines, "\n")
    
    local file = io.open(filename, "w")
    if file then
      file:write(content)
      file:close()
      return true
    end
    
  else
    print("Error: Unsupported format '" .. format .. "'. Use 'lua', 'csv', or 'tsv'")
    return false
  end
  
  print("Error: Could not open file for writing: " .. filename)
  return false
end

----------------------- EVENTS ----------------------

---------------------- KEYBOARD ---------------------

function updateLastKeyPressed()
  local commonKeys = {
    -- Letters
    "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
    -- Numbers
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
    -- Function keys
    "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12",
    -- Special keys
    "space", "return", "escape", "backspace", "delete", "tab",
    -- Arrow keys
    "up", "down", "left", "right",
    -- Navigation
    "home", "end", "pageup", "pagedown", "insert",
    -- Modifiers
    "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt",
    "capslock", "numlock", "scrolllock",
    -- Punctuation
    ".", ",", ";", "'", "/", "\\", "[", "]", "-", "=", "`",
    -- Numpad
    "kp0", "kp1", "kp2", "kp3", "kp4", "kp5", "kp6", "kp7", "kp8", "kp9",
    "kp.", "kp/", "kp*", "kp-", "kp+", "kpenter",
    -- Other
    "pause", "printscreen"
  }
  
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

function keyIsDown(k)
  return L5_env.pressedKeys[k] == true
end

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
  if L5_env.degree_mode == RADIANS then 
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

function applyMatrix(...)
  local args = {...}
  local a, b, c, d, e, f
  
  -- Check if first argument is a table
  if #args == 1 and type(args[1]) == "table" then
    local t = args[1]
    if #t ~= 6 then
        error("applyMatrix() table must contain exactly 6 values")
    end
    a, b, c, d, e, f = t[1], t[2], t[3], t[4], t[5], t[6]
  elseif #args == 6 then
    a, b, c, d, e, f = args[1], args[2], args[3], args[4], args[5], args[6]
  else
    error("applyMatrix() requires either 6 arguments or a table with 6 values")
  end
  
  -- Validate that all values are numbers
  if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" or 
     type(d) ~= "number" or type(e) ~= "number" or type(f) ~= "number" then
      error("applyMatrix() requires all values to be numbers")
  end
  
  -- p5.js matrix format:
  -- | a  c  e |
  -- | b  d  f |
  -- | 0  0  1 |
  
  -- Extract translation
  local tx, ty = e, f
  
  -- Check if it's a pure shear matrix (no rotation/scale, just shear)
  -- Pure x-shear: a=1, b=0, d=1, c=shear
  if a == 1 and b == 0 and d == 1 then
    local transform = love.math.newTransform(tx, ty, 0, 1, 1, 0, 0, c, 0)
    love.graphics.applyTransform(transform)
    return
  end
  
  -- Pure y-shear: a=1, c=0, d=1, b=shear
  if a == 1 and c == 0 and d == 1 then
    local transform = love.math.newTransform(tx, ty, 0, 1, 1, 0, 0, 0, b)
    love.graphics.applyTransform(transform)
    return
  end
  
  -- General case: decompose into scale, rotation, and shear
  local sx = math.sqrt(a * a + b * b)
  local sy = math.sqrt(c * c + d * d)
  local angle = math.atan2(b, a)
  
  -- Calculate shear
  local kx = (a * c + b * d) / (sx * sx)
  local ky = 0
  
  local transform = love.math.newTransform(tx, ty, angle, sx, sy, 0, 0, kx, ky)
  love.graphics.applyTransform(transform)
end

function resetMatrix()
  love.graphics.origin()
end

-------------------- TIME and DATE -------------------

function millis()
  return 1000*love.timer.getTime()
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

function hour()
  return tonumber(os.date("%H"))
end

function minute()
  return tonumber(os.date("%M"))
end

function second()
  return tonumber(os.date("%S"))
end

------------------------ SHAPE -----------------------

-------------------- 2D Primitives -------------------

function rect(_a,_b,_c,_d,_e)
  if L5_env.rect_mode==CORNERS then --x1,y1,x2,y2
    love.graphics.rectangle(L5_env.fill_mode,_a,_b,_c-_a,_d-_b,_e,_e) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.rectangle("line",_a,_b,_c-_a,_d-_b,_e,_e)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.rect_mode==CENTER then --x-w/2,y-h/2,w,h
    love.graphics.rectangle(L5_env.fill_mode, _a-_c/2,_b-_d/2,_c,_d,_e,_e) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c,_d,_e,_e)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.rect_mode==RADIUS then --x-w/2,y-h/2,r1*2,r2*2
    love.graphics.rectangle(L5_env.fill_mode, _a-_c,_b-_d,_c*2,_d*2,_e,_e) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.rectangle("line", _a-_c,_b-_d,_c*2,_d*2,_e,_e)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.rect_mode==CORNER then --CORNER default x,y,w,h
    love.graphics.rectangle(L5_env.fill_mode,_a,_b,_c,_d,_e,_e) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.rectangle("line",_a,_b,_c,_d,_e,_e)
    love.graphics.setColor(r, g, b, a)
  end
end

function square(_a,_b,_c, _d)
  --note: _d is not height! it is radius of rounded corners!
  --CORNERS mode doesn't exist for squares
  if L5_env.rect_mode==CENTER then --x-w/2,y-h/2,w,h
    love.graphics.rectangle(L5_env.fill_mode, _a-_c/2,_b-_c/2,_c,_c,_d,_d) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c,_c,_d,_d)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.rect_mode==RADIUS then --x-w/2,y-h/2,r*2,r*2
    love.graphics.rectangle(L5_env.fill_mode, _a-_c,_b-_c,_c*2,_c*2,_d,_d) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.rectangle("line", _a-_c,_b-_c,_c*2,_c*2,_d,_d)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.rect_mode==CORNER then -- CORNER default x,y,w,h
    love.graphics.rectangle(L5_env.fill_mode,_a,_b,_c,_c,_d,_d) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.rectangle("line",_a,_b,_c,_c,_d,_d)
    love.graphics.setColor(r, g, b, a)
  end
end

function ellipse(_a,_b,_c,_d)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  if not _d then
    _d = _c
  end
  if L5_env.ellipse_mode==RADIUS then 
    love.graphics.ellipse(L5_env.fill_mode,_a,_b,_c,_d) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c,_d)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.ellipse_mode==CORNER then 
    love.graphics.ellipse(L5_env.fill_mode,_a+_c/2,_b+_d/2,_c/2,_d/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a+_c/2,_b+_d/2,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.ellipse_mode==CORNERS then 
    love.graphics.ellipse(L5_env.fill_mode,_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2)
    love.graphics.setColor(r, g, b, a)
  else --default CENTER x,y,w/2,h/2
    love.graphics.ellipse(L5_env.fill_mode,_a,_b,_c/2,_d/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  end
end

function circle(_a,_b,_c)
  if L5_env.ellipse_mode==RADIUS then 
    love.graphics.ellipse(L5_env.fill_mode,_a,_b,_c,_c) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c,_d)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.ellipse_mode==CORNER then 
    love.graphics.ellipse(L5_env.fill_mode,_a+_c/2,_b+_c/2,_c/2,_c/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a+_c/2,_b+_c/2,_c/2,_c/2)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.ellipse_mode==CORNERS then 
    love.graphics.ellipse(L5_env.fill_mode,_a+(_c-_a)/2,_b+(_c-_a)/2,(_c-_a)/2,(_c-_b)/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a+(_c-_a)/2,_b+(_c-_a)/2,(_c-_a)/2,(_c-_b)/2)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.ellipse_mode==CENTER then --default CENTER x,y,w/2,h/2
    love.graphics.ellipse(L5_env.fill_mode,_a,_b,_c/2,_c/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c/2,_c/2)
    love.graphics.setColor(r, g, b, a)
  end
end



function quad(_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) --this is a 4-sided love2d polygon! a quad implies an applied texture
  --for other # of sides, use processing api call createShape
  love.graphics.polygon(L5_env.fill_mode,_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
    love.graphics.setColor(r, g, b, a)
end

function triangle(_x1,_y1,_x2,_y2,_x3,_y3) --this is a 3-sided love2d polygon
  love.graphics.polygon(L5_env.fill_mode,_x1,_y1,_x2,_y2,_x3,_y3) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3)
    love.graphics.setColor(r, g, b, a)
end

--p5 calls arctype parameter "mode"
function arc(_x, _y, _w, _h, _start, _stop, _arctype)
  local arctype = _arctype or PIE

  -- Convert angles to radians if in DEGREES mode
  local start_angle = _start
  local stop_angle = _stop
  
  if L5_env.degree_mode == DEGREES then
    start_angle = math.rad(_start)
    stop_angle = math.rad(_stop)
  end

  local radius_x = _w / 2
  local radius_y = _h / 2

  -- Calculate center based on ellipseMode
  local center_x = _x
  local center_y = _y

  if L5_env.ellipse_mode == CENTER then
    center_x = _x
    center_y = _y
  elseif L5_env.ellipse_mode == RADIUS then
    center_x = _x
    center_y = _y
    radius_x = _w  -- In RADIUS mode, w and h are the radii directly
    radius_y = _h
  elseif L5_env.ellipse_mode == CORNER then
    center_x = _x + radius_x
    center_y = _y + radius_y
  elseif L5_env.ellipse_mode == CORNERS then
    center_x = (_x + _w) / 2
    center_y = (_y + _h) / 2
    radius_x = (_w - _x) / 2
    radius_y = (_h - _y) / 2
  end
  
  -- Normalize angles to [0, 2π) range
  local function normalize_angle(angle)
    local TWO_PI = 2 * math.pi
    angle = angle % TWO_PI
    if angle < 0 then
      angle = angle + TWO_PI
    end
    return angle
  end
  
  local start_norm = normalize_angle(start_angle)
  local stop_norm = normalize_angle(stop_angle)
  
  -- Processing always draws clockwise from start to stop
  local arc_span
  if stop_norm <= start_norm then
    -- Arc crosses the 0° boundary - go the long way around
    arc_span = (2 * math.pi - start_norm) + stop_norm
  else
    -- Normal case - direct clockwise arc
    arc_span = stop_norm - start_norm
  end
  
  -- Check if this should be a full circle
  local epsilon = 1e-6
  local is_full_circle = arc_span >= (2 * math.pi - epsilon)
  
  if is_full_circle then
    -- Draw a full ellipse
    if L5_env.fill_mode and L5_env.fill_mode ~= "line" then
      love.graphics.ellipse("fill", center_x, center_y, radius_x, radius_y)
    end
    
    if L5_env.stroke_color then
      local r, g, b, a = love.graphics.getColor()
      love.graphics.setColor(unpack(L5_env.stroke_color))
      love.graphics.ellipse("line", center_x, center_y, radius_x, radius_y)
      love.graphics.setColor(r, g, b, a)
    end
  else
    -- Handle elliptical arcs (when _w != _h)
    if math.abs(radius_x - radius_y) < epsilon then
      -- Circular arc - use Love2D's built-in arc function
      local radius = radius_x
      
      if L5_env.fill_mode and L5_env.fill_mode ~= "line" then
        love.graphics.arc("fill", arctype, center_x, center_y, radius, start_norm, start_norm + arc_span)
      end
      
      if L5_env.stroke_color then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(unpack(L5_env.stroke_color))
        love.graphics.arc("line", arctype, center_x, center_y, radius, start_norm, start_norm + arc_span)
        love.graphics.setColor(r, g, b, a)
      end
    else
      -- Elliptical arc - need to draw manually with vertices
      draw_elliptical_arc(center_x, center_y, radius_x, radius_y, start_norm, arc_span, arctype)
    end
  end
end

-- Helper function to draw elliptical arcs
function draw_elliptical_arc(cx, cy, rx, ry, start_angle, arc_span, arctype)
  local segments = math.max(8, math.floor(math.abs(arc_span) * 12)) -- Adaptive segments
  local vertices = {}
  
  -- Generate arc vertices
  for i = 0, segments do
    local angle = start_angle + (arc_span * i / segments)
    local x = cx + rx * math.cos(angle)
    local y = cy + ry * math.sin(angle)
    table.insert(vertices, x)
    table.insert(vertices, y)
  end
  
  if arctype == PIE then
    -- Add center point for pie
    table.insert(vertices, 1, cy) -- Insert at position 2 (after first vertex)
    table.insert(vertices, 1, cx) -- Insert at position 1
  elseif arctype == CHORD then
    -- Close the arc by connecting endpoints
    -- vertices already has the right points
  end
  -- "open" type doesn't need modification
  
  -- Draw filled arc
  if L5_env.fill_mode and L5_env.fill_mode ~= "line" and #vertices >= 6 then
    if arctype == "pie" then
      love.graphics.polygon("fill", vertices)
    elseif arctype == CHORD then
      love.graphics.polygon("fill", vertices)
    end
    -- "open" type doesn't get filled
  end
  
  -- Draw stroke
  if L5_env.stroke_color then
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color))
    
    if arctype == OPEN then
      -- Just draw the arc line
      for i = 1, #vertices - 2, 2 do
        love.graphics.line(vertices[i], vertices[i+1], vertices[i+2], vertices[i+3])
      end
    elseif arctype == CHORD then
      -- Draw the arc and the closing line
      love.graphics.polygon("line", vertices)
    elseif arctype == PIE then
      -- Draw the arc and lines to center
      love.graphics.polygon("line", vertices)
    end
    
    love.graphics.setColor(r, g, b, a)
  end
end

function point(_x,_y)
  --Points unaffected by love.graphics.scale - size is always in pixels
  --a line is drawn in the stroke color
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(unpack(L5_env.stroke_color)) 
  love.graphics.points(_x,_y)
  love.graphics.setColor(r, g, b, a)
end

function line(_x1,_y1,_x2,_y2)
  --a line is drawn in the stroke color
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.line(_x1,_y1,_x2,_y2)
    love.graphics.setColor(r, g, b, a)
end

function background(_r,_g,_b,_a)
  if type(_r) == "userdata" and _r:type() == "Image" then
    image(_r,0,0,width,height)
  else
    local prevR, prevG, prevB, prevA = love.graphics.getColor()
    love.graphics.setColor(unpack(toColor(_r,_g,_b,_a)))
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setColor(prevR, prevG, prevB, prevA)
    L5_env.clearscreen = true 
  end
end

function colorMode(_mode, _max1, _max2, _max3, _maxA)
  --handles 4 colorMode variations 
  -- Set the color mode
  if _mode == RGB or _mode == HSB or _mode == HSL then
    L5_env.color_mode = _mode
  else
    error("Invalid color mode. Use RGB, HSB, or HSL")
  end
  
  -- Handle different argument patterns
  if _max1 == nil then
    -- No max specified - use defaults
    if _mode == RGB then 
      L5_env.color_max = {255, 255, 255, 255}
    elseif _mode == HSB or _mode == HSL then 
      L5_env.color_max = {360, 100, 100, 100}
    end
  elseif _max2 == nil then
    -- One max specified - apply to all channels
    L5_env.color_max = {_max1, _max1, _max1, _max1}
  elseif _max3 == nil then
    error("colorMode requires either 1, 3, or 4 max values")
  elseif _maxA == nil then
    -- Three max values specified (no alpha)
    if _mode == RGB then
      L5_env.color_max = {_max1, _max2, _max3, 255}  -- Default alpha
    elseif _mode == HSB or _mode == HSL then
      L5_env.color_max = {_max1, _max2, _max3, 100}  -- Default alpha
    end
  else
    -- Four max values specified (including alpha)
    L5_env.color_max = {_max1, _max2, _max3, _maxA}
  end
end

function fill(...)
  L5_env.fill_mode = "fill"
  local args = {...}
  
  -- If single argument is a table
  if #args == 1 and type(args[1]) == "table" then
    local t = args[1]
    -- Check if it's normalized (all values <= 1.0) or raw array
    if t[1] <= 1.0 and t[2] <= 1.0 and t[3] <= 1.0 and (not t[4] or t[4] <= 1.0) then
      -- Already normalized, use directly
      love.graphics.setColor(unpack(t))
    else
      -- Raw array, needs conversion
      love.graphics.setColor(unpack(toColor(unpack(t))))
    end
  else
    love.graphics.setColor(unpack(toColor(...)))
  end
end

--------------- CREATING and READING ----------------

function color(...)
    local args = {...}
    
    -- Check if first argument is a table
    if #args == 1 and type(args[1]) == "table" then
        local t = args[1]
        if #t == 3 then
            return toColor(t[1], t[2], t[3], L5_env.color_max[4])
        elseif #t == 4 then
            return toColor(t[1], t[2], t[3], t[4])
        else
            error("color() table argument requires 3 or 4 values")
        end
    end
    
    -- Regular argument handling
    if #args == 3 then
        return toColor(args[1], args[2], args[3], L5_env.color_max[4])
    elseif #args == 4 then
        return toColor(args[1], args[2], args[3], args[4])
    elseif #args == 2 then
        return toColor(args[1], args[1], args[1], args[2])
    elseif #args == 1 then
        return toColor(args[1])  
    else
        error("color() requires 1-4 arguments or a table with 3-4 values")
    end
end

function red(_color)
  if type(_color) == "string" then
    -- Convert CSS color string to color object first
    _color = toColor(_color)
  elseif type(_color) ~= "table" then
    error("red() requires a color table or CSS string")
  end
  
  -- Check if it's a normalized color object (values 0-1) from color() function
  -- versus a raw array with values in the current color mode range
  if _color[1] <= 1.0 and _color[2] <= 1.0 and _color[3] <= 1.0 then
    -- It's normalized - scale to current color mode range
    return _color[1] * L5_env.color_max[1]
  else
    -- It's a raw array - already in color mode range, return as-is
    return _color[1]
  end
end

function green(_color)
  if type(_color) == "string" then
    -- Convert CSS color string to color object first
    _color = toColor(_color)
  elseif type(_color) ~= "table" then
    error("green() requires a color table or CSS string")
  end
  
  -- Check if it's a normalized color object (values 0-1) from color() function
  -- versus a raw array with values in the current color mode range
  if _color[1] <= 1.0 and _color[2] <= 1.0 and _color[3] <= 1.0 then
    -- It's normalized - scale to current color mode range
    return _color[2] * L5_env.color_max[2]
  else
    -- It's a raw array - already in color mode range, return as-is
    return _color[2]
  end
end

function blue(_color)
  if type(_color) == "string" then
    -- Convert CSS color string to color object first
    _color = toColor(_color)
  elseif type(_color) ~= "table" then
    error("blue() requires a color table or CSS string")
  end
  
  -- Check if it's a normalized color object (values 0-1) from color() function
  -- versus a raw array with values in the current color mode range
  if _color[1] <= 1.0 and _color[2] <= 1.0 and _color[3] <= 1.0 then
    -- It's normalized - scale to current color mode range
    return _color[3] * L5_env.color_max[3]
  else
    -- It's a raw array - already in color mode range, return as-is
    return _color[3]
  end
end

function alpha(_color)
  if type(_color) == "string" then
    -- Convert CSS color string to color object first
    _color = toColor(_color)
  elseif type(_color) ~= "table" then
    error("alpha() requires a color table or CSS string")
  end
  
  -- Check if it's a normalized color object (values 0-1) from color() function
  -- versus a raw array with values in the current color mode range
  if _color[1] <= 1.0 and _color[2] <= 1.0 and _color[3] <= 1.0 then
    -- It's normalized - scale to current color mode range
    return _color[4] * L5_env.color_max[4]
  else
    -- It's a raw array - already in color mode range, return as-is
    return _color[4]
  end
end

function brightness(_color)
  if type(_color) == "string" then
    -- Convert CSS color string to color object first
    _color = toColor(_color)
  elseif type(_color) ~= "table" then
    error("brightness() requires a color table or CSS string")
  end
  
  -- Check if it's a normalized color object (values 0-1) or raw array
  local isNormalized = _color[1] <= 1.0 and _color[2] <= 1.0 and _color[3] <= 1.0
  
  local r, g, b
  if isNormalized then
    -- Already normalized (0-1)
    r, g, b = _color[1], _color[2], _color[3]
  else
    -- Raw array - normalize it
    r = _color[1] / L5_env.color_max[1]
    g = _color[2] / L5_env.color_max[2]
    b = _color[3] / L5_env.color_max[3]
  end
  
  -- Convert RGB to HSB and extract brightness (which is the V in HSV)
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local brightness = max  -- Brightness is the max of RGB values
  
  -- Return brightness in the current color mode range
  if L5_env.color_mode == HSB then
    return brightness * L5_env.color_max[3]
  else
    -- Default: return in 0-100 range
    return brightness * 100
  end
end

function lightness(_color)
  if type(_color) == "string" then
    -- Convert CSS color string to color object first
    _color = toColor(_color)
  elseif type(_color) ~= "table" then
    error("lightness() requires a color table or CSS string")
  end
  
  -- Check if it's a normalized color object (values 0-1) or raw array
  local isNormalized = _color[1] <= 1.0 and _color[2] <= 1.0 and _color[3] <= 1.0
  
  local r, g, b
  if isNormalized then
    -- Already normalized (0-1) from toColor()
    r, g, b = _color[1], _color[2], _color[3]
  else
    -- Raw array - normalize based on current color mode
    if L5_env.color_mode == RGB then
      r = _color[1] / L5_env.color_max[1]
      g = _color[2] / L5_env.color_max[2]
      b = _color[3] / L5_env.color_max[3]
    elseif L5_env.color_mode == HSL then
      -- Raw HSL array - convert to RGB first
      r, g, b = HSLtoRGB(_color[1] / L5_env.color_max[1], _color[2] / L5_env.color_max[2], _color[3] / L5_env.color_max[3])
    elseif L5_env.color_mode == HSB then
      -- Raw HSB array - convert to RGB first
      r, g, b = HSVtoRGB(_color[1] / L5_env.color_max[1], _color[2] / L5_env.color_max[2], _color[3] / L5_env.color_max[3])
    end
  end
  
  -- Convert RGB to HSL lightness
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local lightness = (max + min) / 2
  
  -- Return lightness in the current color mode range
  if L5_env.color_mode == HSL then
    return lightness * L5_env.color_max[3]
  else
    -- Default: return in 0-100 range
    return lightness * 100
  end
end

function hue(_color)
  if type(_color) == "string" then
    _color = toColor(_color)
  elseif type(_color) ~= "table" then
    error("hue() requires a color table or CSS string")
  end
  
  -- toColor() always returns normalized 0-1 values
  -- Raw arrays have values in the color_max range
  -- If all values are <= 1, it's normalized; otherwise it's raw
  local isNormalized = _color[1] <= 1.0 and _color[2] <= 1.0 and _color[3] <= 1.0
  
  local r, g, b
  if isNormalized then
    -- Already normalized (0-1) from toColor()
    r, g, b = _color[1], _color[2], _color[3]
  else
    -- Raw array - normalize based on current color mode
    if L5_env.color_mode == RGB then
      r = _color[1] / L5_env.color_max[1]
      g = _color[2] / L5_env.color_max[2]
      b = _color[3] / L5_env.color_max[3]
    elseif L5_env.color_mode == HSL then
      -- Raw HSL array - convert to RGB first
      r, g, b = HSLtoRGB(_color[1] / L5_env.color_max[1], _color[2] / L5_env.color_max[2], _color[3] / L5_env.color_max[3])
    elseif L5_env.color_mode == HSB then
      -- Raw HSB array - convert to RGB first
      r, g, b = HSVtoRGB(_color[1] / L5_env.color_max[1], _color[2] / L5_env.color_max[2], _color[3] / L5_env.color_max[3])
    end
  end
  
  -- Convert RGB to hue
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local delta = max - min
  
  local h = 0
  if delta ~= 0 then
    if max == r then
      h = ((g - b) / delta) % 6
    elseif max == g then
      h = (b - r) / delta + 2
    else
      h = (r - g) / delta + 4
    end
    h = h * 60
    if h < 0 then h = h + 360 end
  end
  
  -- Return hue in the current color mode range
  if L5_env.color_mode == HSB or L5_env.color_mode == HSL then
    return (h / 360) * L5_env.color_max[1]
  else
    return h
  end
end

function lerpColor(_c1, _c2, _amt)
  -- Clamp amt to [0, 1]
  _amt = math.max(0, math.min(1, _amt))
  
  -- Convert string colors if needed
  if type(_c1) == "string" then
    _c1 = toColor(_c1)
  end
  if type(_c2) == "string" then
    _c2 = toColor(_c2)
  end
  
  -- Check if colors are normalized or raw arrays
  local c1_normalized = _c1[1] <= 1.0 and _c1[2] <= 1.0 and _c1[3] <= 1.0
  local c2_normalized = _c2[1] <= 1.0 and _c2[2] <= 1.0 and _c2[3] <= 1.0
  
  -- Normalize colors if needed
  local c1, c2
  if c1_normalized then
    c1 = {_c1[1] * L5_env.color_max[1], _c1[2] * L5_env.color_max[2], _c1[3] * L5_env.color_max[3], _c1[4] * L5_env.color_max[4]}
  else
    c1 = {_c1[1], _c1[2], _c1[3], _c1[4] or L5_env.color_max[4]}
  end
  
  if c2_normalized then
    c2 = {_c2[1] * L5_env.color_max[1], _c2[2] * L5_env.color_max[2], _c2[3] * L5_env.color_max[3], _c2[4] * L5_env.color_max[4]}
  else
    c2 = {_c2[1], _c2[2], _c2[3], _c2[4] or L5_env.color_max[4]}
  end
  
  -- Interpolate in the current color mode
  local result = {}
  for i = 1, 4 do
    result[i] = c1[i] + (c2[i] - c1[i]) * _amt
  end
  
  -- Convert back to normalized format (what toColor returns)
  return {
    result[1] / L5_env.color_max[1],
    result[2] / L5_env.color_max[2],
    result[3] / L5_env.color_max[3],
    result[4] / L5_env.color_max[4]
  }
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
  if _mode == CORNER or _mode == CORNERS or _mode == CENTER or _mode == RADIUS then
    L5_env.rect_mode = _mode
  else
    error("rectMode() must be CORNER, CORNERS, CENTER, or RADIUS")
  end
end

function ellipseMode(_mode)
  if _mode == CENTER or _mode == CORNER or _mode == CORNERS or _mode == RADIUS then
    L5_env.ellipse_mode = _mode
  else
    error("ellipseMode() must be CENTER, CORNER, CORNERS, or RADIUS")
  end
end

function imageMode(_mode)
  if _mode == CORNER or _mode == CENTER or _mode == CORNERS then
    L5_env.image_mode = _mode
  else
    error("imageMode() must be CORNER, CENTER, or CORNERS")
  end
end

function noFill()
  L5_env.fill_mode="line" 
end

function strokeWeight(_w)
  love.graphics.setLineWidth(_w)
  love.graphics.setPointSize(_w) --also sets sizing on points
end

function strokeJoin(_style)
  love.graphics.setLineJoin(_style)
end

function noSmooth()
  love.graphics.setDefaultFilter("nearest", "nearest", 1)
  love.graphics.setLineStyle('rough')

end

function smooth()
  love.graphics.setDefaultFilter("linear", "linear", 1)
  love.graphics.setLineStyle('smooth')
end

function stroke(_r,_g,_b,_a)
  L5_env.stroke_color = toColor(_r,_g,_b,_a) 
end

function noStroke()
  L5_env.stroke_color={0,0,0,0} 
end

------------------ RENDERING ------------------------
function createGraphics(_width, _height)
    local pg = {}
    
    -- Create the offscreen buffer
    pg._canvas = love.graphics.newCanvas(_width, _height)
    pg.width = _width or width
    pg.height = _height or height
    pg._previousCanvas = nil
    pg._drawing = false
    
    -- Begin drawing to this graphics buffer
    function pg:beginDraw()
        if self._drawing then
            error("beginDraw() called while already drawing to this buffer")
        end
        self._previousCanvas = love.graphics.getCanvas()
        love.graphics.setCanvas(self._canvas)
        self._drawing = true
    end
    
    -- End drawing to this graphics buffer
    function pg:endDraw()
        if not self._drawing then
            error("endDraw() called without beginDraw()")
        end
        love.graphics.setCanvas(self._previousCanvas)
        self._previousCanvas = nil
        self._drawing = false
    end
    
    -- Get the canvas for drawing to screen
    function pg:getCanvas()
        return self._canvas
    end
    
    return pg
end

-------------------- VERTEX -------------------------

function texture(_img)
  -- to be applied to vertices
  L5_env.currentTexture = _img
  L5_env.useTexture = true
end

function textureMode(_mode)
    -- Set how texture coordinates are interpreted
    -- NORMAL - coordinates are 0 to 1 (default)
    -- IMAGE - coordinates are in pixel dimensions
    if _mode == NORMAL or _mode == IMAGE then
        L5_env.textureMode = _mode
    else
        error("textureMode must be NORMAL or IMAGE")
    end
end

function textureWrap(_mode)
    -- Set texture wrapping mode
    -- Valid modes: CLAMP or REPEAT
    if _mode == CLAMP or _mode == REPEAT then
      L5_env.textureWrap = _mode
    else
      error("textureWrap must be CLAMP or REPEAT")
    end
end

function beginShape()
  -- reset custom shape vertices table
  L5_env.vertices = {}
  L5_env.useTexture = false
end

function vertex(_x, _y, _u, _v)
    -- add vertex (x, y) to the custom shape vertices table
    if _u ~= nil and _v ~= nil then
      local texU, texV = _u, _v

      if L5_env.textureMode == IMAGE and L5_env.currentTexture then
	-- Convert from pixel coordinates to normalized 0-1 range
	texU = _u / L5_env.currentTexture:getWidth()
	texV = _v / L5_env.currentTexture:getHeight()
      end
      table.insert(L5_env.vertices, {_x, _y, texU, texV})
    else
      table.insert(L5_env.vertices, _x)
      table.insert(L5_env.vertices, _y)
    end
end

function endShape()
    -- draw the custom shape
    if #L5_env.vertices > 0 then
      if L5_env.useTexture and L5_env.currentTexture then
	-- Use mesh for textured polygon
	local mesh = love.graphics.newMesh(L5_env.vertices, "fan")
	mesh:setTexture(L5_env.currentTexture)

        -- Apply texture wrap mode
            L5_env.currentTexture:setWrap(L5_env.textureWrap, L5_env.textureWrap)

	love.graphics.draw(mesh)
      else
        -- Use regular polygon for non-textured shapes
        love.graphics.polygon("fill", L5_env.vertices)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(unpack(L5_env.stroke_color))
        love.graphics.polygon("line", L5_env.vertices)
	love.graphics.setColor(r, g, b, a)
      end
    end
end

function bezier(x1,y1,x2,y2,x3,y3,x4,y4)
  local curve = love.math.newBezierCurve({x1,y1,x2,y2,x3,y3,x4,y4})
  local points = curve:render()
  
  -- Draw fill if fill mode is set
  if L5_env.fill_mode == "fill" then
    -- Close the shape by connecting end point back to start
    local closedPoints = {}
    for i, v in ipairs(points) do
      table.insert(closedPoints, v)
    end
    -- Add line back to start to close the shape
    table.insert(closedPoints, x1)
    table.insert(closedPoints, y1)
    
    love.graphics.polygon("fill", closedPoints)
  end
  
  -- Draw stroke
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(unpack(L5_env.stroke_color))
  love.graphics.line(points)
  love.graphics.setColor(r, g, b, a)
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
function fract(_n)
  return _n - int(_n)
end

function log(_n)
  return math.log(_n)
end

function pow(n, e)
  return n ^ e
end

function exp(n)
  return math.exp(n)
end

function norm(val, start, stop)
  -- normalize the value to 0-1 range
  return (val - start) / (stop - start)
end

function lerp(start, stop, amt)
  return start + (stop - start) * amt
end

function sq(n)
  return n * n
end

function sqrt(n)
  return math.sqrt(n)
end

function random(_a,_b)
  if _b then
    return love.math.random()*(_b-_a)+_a
  elseif _a then
    if type(_a) == 'table' then
      -- more robust in case a table isn't ordered by integers
      local keyset = {}
      for k in pairs(_a) do
	  table.insert(keyset, k)
      end
      return _a[keyset[math.floor(love.math.random() * #keyset) + 1]]
    elseif type(_a) == 'number' then
      return love.math.random()*_a
    end
  else
    return love.math.random()
  end
end

function randomSeed(seed)
  love.math.setRandomSeed(seed)
end

function noise(_x,_y,_z)
  return love.math.noise(_x,_y,_z)
end

--self-contained, optional params
randomGaussian = (function()
  local hasSpare = false
  local spare = 0
  
  return function(mean, sd)
    mean = mean or 0
    sd = sd or 1
    
    local val
    
    if hasSpare then
      val = spare
      hasSpare = false
    else
      local u, v, s
      repeat
        u = math.random() * 2 - 1
        v = math.random() * 2 - 1
        s = u * u + v * v
      until s > 0 and s < 1
      
      s = math.sqrt(-2 * math.log(s) / s)
      val = u * s
      spare = v * s
      hasSpare = true
    end
    
    return val * sd + mean
  end
end)()

function abs(_a)
  return math.abs(_a)
end

function round(n, decimals)
  decimals = decimals or 0
  local mult = 10 ^ decimals
  return math.floor(n * mult + 0.5 * (n >= 0 and 1 or -1)) / mult
end

function int(_a)
    -- Handle table input
    if type(_a) == "table" then
        local result = {}
        for i, v in ipairs(_a) do
            result[i] = int(v)  -- Recursively convert each element
        end
        return result
    end
    
    local num
    
    if type(_a) == "string" then
        num = tonumber(_a)
        if num == nil then return nil end
    elseif type(_a) == "boolean" then
        num = _a and 1 or 0
    elseif type(_a) == "number" then
        num = _a
    else
        return nil
    end
    
    -- check for invalid numbers
    if num ~= num or num == math.huge or num == -math.huge then
        return nil
    end
    
    -- strip decimal via floor
    return math.floor(num)
end

function ceil(_a)
  return math.ceil(_a)
end

function floor(_a)
  return math.floor(_a)
end

function max(...)
  local args = {...}
  -- If single table argument, unpack it
  if #args == 1 and type(args[1]) == "table" then
    return math.max(unpack(args[1]))
  else
    return math.max(unpack(args))
  end
end

function min(...)
  local args = {...}
  -- If single table argument, unpack it
  if #args == 1 and type(args[1]) == "table" then
    return math.min(unpack(args[1]))
  else
    return math.min(unpack(args))
  end
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
    return L5_env.degree_mode
  elseif _mode == RADIANS or _mode == DEGREES then
    L5_env.degree_mode = _mode
  else
    error("angleMode() must be RADIANS or DEGREES")
  end
end

function degrees(_angle)
  return math.deg(_angle)
end

function radians(_angle)
  return math.rad(_angle)
end

function sin(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.sin(_angle)
  else
    return math.sin(radians(_angle))
  end
end

function asin(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.asin(_angle)
  else
    return math.asin(radians(_angle))
  end
end

function cos(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.cos(_angle)
  else
    return math.cos(radians(_angle))
  end
end

function acos(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.acos(_angle)
  else
    return math.acos(radians(_angle))
  end
end

function tan(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.tan(_angle)
  else
    return math.tan(radians(_angle))
  end
end

function atan(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.atan(_angle)
  else
    return math.atan(radians(_angle))
  end
end

function atan2(y, x)
  local angle = math.atan2(y, x)  -- This returns radians
  
  if L5_env.degree_mode == DEGREES then
    return math.deg(angle)  -- convert to degrees 
  else
    return angle  -- or keep in default radians 
  end
end

---------------------- DATA ------------------------

function boolean(n)
  if type(n) == "table" then
    local result = {}
    for i, v in ipairs(n) do
      result[i] = boolean(v)  -- Recursively convert each element
    end
    return result
  end
  
  if type(n) == "string" then
    return n == "true"
  end
  
  if type(n) == "number" then
    return n ~= 0
  end
  
  if type(n) == "boolean" then
    return n
  end
  
  return false
end

function byte(n)
    if type(n) == "table" then
    local result = {}
    for i, v in ipairs(n) do
      result[i] = byte(v)  
    end
    return result
  end
  
  if type(n) == "boolean" then
    return n and 1 or 0
  end
  
  -- Handle strings by converting to number first, or get first character's byte value
  if type(n) == "string" then
    -- Try to convert to number
    local num = tonumber(n)
    if num then
      n = num
    else
      -- Get first character's byte value using string library
      n = string.byte(n, 1) or 0
    end
  end
  
  if type(n) == "number" then
    -- Convert to integer
    local int_val = math.floor(n)
    
    -- Wrap to byte range (-128 to 127)
    local wrapped = int_val % 256
    
    -- Convert to signed byte range
    if wrapped > 127 then
      wrapped = wrapped - 256
    end
    
    return wrapped
  end
  
  -- Default case
  return 0
end

function char(n)
  if type(n) == "table" then
    local result = {}
    for i, v in ipairs(n) do
      result[i] = char(v)  
    end
    return result
  end
  
  -- handle strings by converting to number first
  if type(n) == "string" then
    local num = tonumber(n)
    if num then
      n = math.floor(num)
    else
      -- if not a valid number, return first character or empty string
      return n:sub(1, 1)
    end
  end
  
  if type(n) == "number" then
    local int_val = math.floor(n)
    -- Convert to character using string.char
    -- handle out of range values gracefully
    if int_val >= 0 and int_val <= 1114111 then  -- Valid Unicode range
      local success, result = pcall(string.char, int_val)
      if success then
        return result
      end
    end
    return ""
  end
  
  -- handle booleans via converting to string
  if type(n) == "boolean" then
    return n and "1" or "0"
  end
  
  -- default case
  return ""
end

function float(str)
  if type(str) == "table" then
    local result = {}
    for i, v in ipairs(str) do
      result[i] = float(v)  
    end
    return result
  end
  
  -- pass through numbers
  if type(str) == "number" then
    return str
  end
  
  if type(str) == "boolean" then
    return str and 1.0 or 0.0
  end
  
  if type(str) == "string" then
    -- Trim whitespace
    str = str:match("^%s*(.-)%s*$")
    
    -- try to convert to number (returns nil on failure)
    return tonumber(str)
  end
  
  -- Default case for anything else (including nil)
  return nil
end

function hex(n, digits)
  if type(n) == "table" then
    local result = {}
    for i, v in ipairs(n) do
      result[i] = hex(v, digits)
    end
    return result
  end
  
  -- Default to 8 digits if not specified (matches p5.js)
  digits = digits or 8
  
  -- convert to int
  local int_val = math.floor(tonumber(n) or 0)
  
  -- convert to hex string uppercase
  local hex_str = string.format("%X", int_val)
  
  -- pad with zeros if needed
  if #hex_str < digits then
    hex_str = string.rep("0", digits - #hex_str) .. hex_str
  end
  
  return hex_str
end

function str(n)
  if type(n) == "table" then
    local result = {}
    for i, v in ipairs(n) do
      result[i] = str(v)
    end
    return result
  end
  
  if type(n) == "boolean" then
    return n and "true" or "false"
  end
  
  if type(n) == "number" then
    return tostring(n)
  end
  
  -- pass through strings
  if type(n) == "string" then
    return n
  end
  
  return tostring(n)
end

function unchar(n)
  if type(n) == "table" then
    local result = {}
    for i, v in ipairs(n) do
      result[i] = unchar(v)
    end
    return result
  end
  
  if type(n) == "string" then
    -- get byte value of the first character
    if #n > 0 then
      return string.byte(n, 1)
    else
      return nil
    end
  end
  
  -- pass through numbers
  if type(n) == "number" then
    return n
  end
  
  -- default
  return nil
end

function unhex(n)
  if type(n) == "table" then
    local result = {}
    for i, v in ipairs(n) do
      result[i] = unhex(v)
    end
    return result
  end
  
  if type(n) == "string" then
    -- trim whitespace
    n = n:match("^%s*(.-)%s*$")
    
    -- convert hex string to number
    return tonumber(n, 16)  -- base 16
  end
  
  -- pass through any numbers
  if type(n) == "number" then
    return n
  end
  
  -- default
  return nil
end

------------------- TYPOGRAPHY ---------------------

function loadFont(fontPath)
  local font = love.graphics.newFont(fontPath)
  -- Store the path so we can recreate the font at different sizes
  L5_env.fontPaths[font] = fontPath
  return font
end

function textFont(font, size)
  -- Update size if provided
  if size then
    L5_env.currentFontSize = size
  end
  
  -- Font object - look up its stored path
  L5_env.currentFontPath = L5_env.fontPaths[font]
  if L5_env.currentFontPath then
    -- Recreate font with current size using stored path
    L5_env.currentFont = love.graphics.newFont(L5_env.currentFontPath, L5_env.currentFontSize)
  else
    -- No path found, use font as-is (won't be resizable)
    L5_env.currentFont = font
  end
  love.graphics.setFont(L5_env.currentFont)
end

function textSize(size)
  L5_env.currentFontSize = size
  if L5_env.currentFontPath then
    -- We have a path, recreate with new size
    L5_env.currentFont = love.graphics.newFont(L5_env.currentFontPath, size)
  else
    -- No path stored, use default font
    L5_env.currentFont = love.graphics.newFont(size)
  end
  love.graphics.setFont(L5_env.currentFont)
end

function textWidth(text)
  if L5_env.currentFont then
    return L5_env.currentFont:getWidth(text)
  end
  return 0
end

function textHeight()
  if L5_env.currentFont then
    return L5_env.currentFont:getHeight()
  end
  return 0
end

--------------------- SYSTEM -----------------------
function exit()
  os.exit()
end

function windowTitle(_title)
  if _title ~= nil then
    love.window.setTitle(_title)
  else 
    return love.window.getTitle()
  end
end

function resizeWindow(_w, _h)
  if _w == nil or _h == nil then --check for 2 args
    error("resizeWindow() requires two arguments: width and height")
  end
  if type(_w) ~= "number" or type(_h) ~= "number" then -- Check if args are numbers
    error("resizeWindow() requires width and height to be numbers")
  end
  if _w <= 0 or _h <= 0 then -- Check for reasonable values 
    error("resizeWindow() requires positive width and height values")
  end

  -- clear active canvas first
  love.graphics.setCanvas()  
  -- then resize
  love.window.setMode(_w, _h)

  -- manually resize window
  love.resize(_w, _h)
end

function clear()
  love.graphics.clear()
end

function displayDensity()
  return love.graphics.getDPIScale()
end

function frameRate(_inp)
  if _inp then --change frameRate
    L5_env.framerate = _inp 
  else --get frameRate
    return love.timer.getFPS( )
  end
end

function noLoop()
  L5_env.drawing = false 
end

function loop()
  L5_env.drawing = true 
end

function isLooping()
  if L5_env.drawing then 
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

function text(_msg,_x,_y,_w)
  if _msg == nil then
    return  -- Don't draw anything if message is nil
  end
  _msg = tostring(_msg)  -- Convert to string in case it's a number, boolean, etc.
  
  local x_offset=0
  local y_offset=0
  local font = love.graphics.getFont()
  
  -- set x-offset
  if L5_env.textAlignX==LEFT then
    x_offset = 0
  elseif L5_env.textAlignX == RIGHT then
    x_offset = font:getWidth(_msg)
  elseif L5_env.textAlignX == CENTER then
    x_offset = font:getWidth(_msg)/2
  end
  
  -- set y-offset
  -- For wrapped text (when _w is specified), treat BASELINE as TOP
  local effectiveAlignY = L5_env.textAlignY
  if _w ~= nil and effectiveAlignY == BASELINE then
    effectiveAlignY = TOP
  end
  
  if effectiveAlignY == BASELINE then
    y_offset = font:getAscent()
  elseif effectiveAlignY == TOP then
    y_offset = 0
  elseif effectiveAlignY == CENTER then
    y_offset = font:getHeight()/2
  elseif effectiveAlignY == BOTTOM then
    y_offset = font:getHeight()
  end
  
  if _w ~= nil then
    local wrapStyle = L5_env.textWrap
    
    if wrapStyle == CHAR then
      -- Manual character wrapping (ASCII only)
      local wrappedText = ""
      local currentLine = ""
      local lineWidth = 0
      
      for i = 1, #_msg do
        local char = _msg:sub(i, i)
        local charWidth = font:getWidth(char)
        
        if lineWidth + charWidth > _w then
          wrappedText = wrappedText .. currentLine .. "\n"
          currentLine = char
          lineWidth = charWidth
        else
          currentLine = currentLine .. char
          lineWidth = lineWidth + charWidth
        end
      end
      wrappedText = wrappedText .. currentLine
      
      love.graphics.printf(wrappedText, _x - x_offset, _y - y_offset, _w, L5_env.textAlignX)
    else
      -- Default WORD wrapping (LÖVE's default behavior)
      love.graphics.printf(_msg, _x - x_offset, _y - y_offset, _w, L5_env.textAlignX)
    end
  else
    -- No specified max width/wrap
    love.graphics.print(_msg, _x - x_offset, _y - y_offset)
  end
end

function textAlign(x_alignment,y_alignment)
  if x_alignment == LEFT or x_alignment == RIGHT or x_alignment == CENTER then
    L5_env.textAlignX=x_alignment
  end
  if y_alignment and (y_alignment == TOP or y_alignment == CENTER or y_alignment == BOTTOM or y_alignment == BASELINE) then
    L5_env.textAlignY=y_alignment
  else
    L5_env.textAlignY=BASELINE
  end
end

function textWrap(_style)
  -- If no argument, return current style
  if _style == nil then
    return L5_env.textWrap
  end
  
  -- Set the wrap style
  if _style == WORD or _style == CHAR then
    L5_env.textWrap = _style
  else
    error("textWrap() style must be WORD or CHAR")
  end
end

---------------- LOADING & DISPLAYING ----------------

function loadImage(_filename)
  local success, result = pcall(love.graphics.newImage, _filename)
  
  if success then
    return result
  else
    error("Failed to load image '" .. _filename .. "': " .. tostring(result))
  end
end

function loadVideo(_filename)
  local success, result = pcall(love.graphics.newVideo, _filename)
  
  if not success then
    error("Failed to load video '" .. _filename .. "': " .. tostring(result))
  end
  
  -- Create a wrapper with additional methods
  local videoWrapper = {
    _video = result,
    _shouldLoop = false,  -- Add loop flag
    
    -- pause override
    pause = function(self)
      self._manuallyPaused = true
      self._video:pause()
    end,

    -- stop method - pause and rewind
    stop = function(self)
      self._manuallyPaused = true
      self._video:pause()
      self._video:rewind()
    end,

    -- play override  
    play = function(self)
      self._manuallyPaused = false
      self._video:play()
    end,

    -- loop() method
    loop = function(self)
      self._shouldLoop = true
      self._manuallyPaused = false
      self._video:play()
    end,
    
    -- noLoop() method
    noLoop = function(self)
      self._shouldLoop = false
    end,
    
    -- time() method
    time = function(self, t)
      if t == nil then
        return self._video:tell()
      else
        self._video:seek(t)
      end
    end,
    
    -- volume() method
    volume = function(self, val)
      if val == nil then
        local source = self._video:getSource()
        return source and source:getVolume() or 1
      else
        local source = self._video:getSource()
        if source then
          source:setVolume(val)
        end
      end
    end
  }
  
  -- Create metatable
  setmetatable(videoWrapper, {
    __index = function(t, key)
      if rawget(t, key) then
        return rawget(t, key)
      end
      local value = t._video[key]
      if type(value) == "function" then
        return function(_, ...) return value(t._video, ...) end
      end
      return value
    end
  })
  
  -- Register video for loop tracking
  L5_env.videos = L5_env.videos or {}
  table.insert(L5_env.videos, videoWrapper)
  
  return videoWrapper
end

function image(_img,_x,_y,_w,_h)
  local originalWidth = _img:getWidth()
  local originalHeight = _img:getHeight()
  local xscale, yscale, ox, oy
  
  if L5_env.image_mode == CENTER then 
    -- CENTER mode: _x,_y is center, _w,_h are width and height
    xscale = _w and (_w/originalWidth) or 1
    yscale = _h and (_h/originalHeight) or xscale
    ox = originalWidth/2
    oy = originalHeight/2
  elseif L5_env.image_mode == CORNERS then
    -- CORNERS mode: (_x,_y) is top-left corner, (_w,_h) is bottom-right corner
    local width = _w - _x
    local height = _h - _y
    xscale = width / originalWidth
    yscale = height / originalHeight
    ox, oy = 0, 0
  else -- CORNER mode (default)
    -- CORNER mode: _x,_y is top-left, _w,_h are width and height
    xscale = _w and (_w/originalWidth) or 1
    yscale = _h and (_h/originalHeight) or xscale
    ox, oy = 0, 0
  end
  
  love.graphics.draw(_img,_x,_y,0,xscale,yscale,ox,oy)
end

function tint(...)
  local args = {...}
  if #args == 1 and type(args[1]) == "table" then
    L5_env.currentTint = toColor(unpack(args[1]))
  else
    L5_env.currentTint = toColor(...)
  end
end

function noTint()
    L5_env.currentTint = {1, 1, 1, 1} 
end

-- Override love.graphics.draw to automatically apply tint
local originalDraw = love.graphics.draw
function love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    local prevR, prevG, prevB, prevA = love.graphics.getColor()
    
    -- Check if it's a video wrapper (our custom table)
    local actualDrawable = drawable
    if type(drawable) == "table" and drawable._video then
        actualDrawable = drawable._video  -- Unwrap to get the real video
    end
    
    -- Handle Image and Video objects
    if type(actualDrawable) == "userdata" and 
       (actualDrawable:type() == "Image" or actualDrawable:type() == "Video") then
        if L5_env.currentTint then
            love.graphics.setColor(unpack(L5_env.currentTint))
        else
            love.graphics.setColor(1, 1, 1, 1)  -- No tint = white
        end
    end
    
    originalDraw(actualDrawable, x, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.setColor(prevR, prevG, prevB, prevA)
end

function cursor(_cursor_icon, hotX, hotY)
  love.mouse.setVisible(true)
  local _cursor_icon = _cursor_icon or "arrow"
  local hotX = hotX or 0
  local hotY = hotY or 0
  
  -- Check if it's a system cursor type
  local systemCursors = {
    "arrow", "ibeam", "wait", "crosshair", "waitarrow", 
    "sizenwse", "sizenesw", "sizewe", "sizens", "sizeall", 
    "no", "hand"
  }
  
  local isSystemCursor = false
  for _, cursorType in ipairs(systemCursors) do
    if _cursor_icon == cursorType then
      isSystemCursor = true
      break
    end
  end
  
  if isSystemCursor then
    -- Use system cursor
    local _cursor = love.mouse.getSystemCursor(_cursor_icon)
    love.mouse.setCursor(_cursor)
  elseif type(_cursor_icon) == "userdata" and _cursor_icon:type() == "ImageData" then
    -- Use ImageData directly
    local _cursor = love.mouse.newCursor(_cursor_icon, hotX, hotY)
    love.mouse.setCursor(_cursor)
  elseif type(_cursor_icon) == "string" then
    -- Treat as file path to custom cursor image
    local cursorImage = love.image.newImageData(_cursor_icon)
    local _cursor = love.mouse.newCursor(cursorImage, hotX, hotY)
    love.mouse.setCursor(_cursor)
  end
end

function noCursor()
  love.mouse.setVisible(false)
end

---------------------- Pixels ----------------------

function copy(source, sx, sy, sw, sh, dx, dy, dw, dh)
    -- If source is nil, try to use the current canvas
    if source == nil then
        source = love.graphics.getCanvas()
        
        -- If still nil, we can't copy from the screen
        if source == nil then
            error("copy() requires a source image or an active canvas")
        end
    end
    
    local quad = love.graphics.newQuad(sx, sy, sw, sh, 
                                       source:getDimensions())
    
    local scaleX = dw / sw
    local scaleY = dh / sh
    love.graphics.draw(source, quad, dx, dy, 0, scaleX, scaleY)
end

function blend(source, sx, sy, sw, sh, dx, dy, dw, dh, blendMode)
  -- allows blend, normal, add, multiply, screen, lightest, darkest, replace
  -- would need to be implemented with shaders: DIFFERENCE, EXCLUSION, OVERLAY, HARD_LIGHT, SOFT_LIGHT, DODGE, BURN
    if source == nil then
        source = love.graphics.getCanvas()
        
        if source == nil then
            error("blend() requires a source image or an active canvas")
        end
    end
    
    local quad = love.graphics.newQuad(sx, sy, sw, sh, 
                                       source:getDimensions())
    
    -- Save previous blend mode
    local previousMode, previousAlphaMode = love.graphics.getBlendMode()
    
    -- Map p5.js blend modes to LÖVE2D
    local mode, alphaMode = "alpha", "alphamultiply"
    
    if blendMode == BLEND or blendMode == NORMAL then
        mode, alphaMode = "alpha", "alphamultiply"
    elseif blendMode == ADD then
        mode, alphaMode = "add", "alphamultiply"
    elseif blendMode == MULTIPLY then
        mode, alphaMode = "multiply", "premultiplied"
    elseif blendMode == SCREEN then
        mode, alphaMode = "screen", "premultiplied"
    elseif blendMode == LIGHTEST then
        mode, alphaMode = "lighten", "premultiplied"
    elseif blendMode == DARKEST then
        mode, alphaMode = "darken", "premultiplied"
    elseif blendMode == REPLACE then
        mode, alphaMode = "replace", "alphamultiply"
      else
	error("Unknown blend mode "..tostring(blendMode)..". Must be of type: BLEND, NORMAL, ADD, MULTIPLY, SCREEN, LIGHTEST, DARKEST, REPLACE.")
    end
    
    love.graphics.setBlendMode(mode, alphaMode)
    
    local scaleX = dw / sw
    local scaleY = dh / sh
    love.graphics.draw(source, quad, dx, dy, 0, scaleX, scaleY)
    
    love.graphics.setBlendMode(previousMode, previousAlphaMode)
end

function filter(_name, _param)
  if _name == GRAY then
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.grayscale
  elseif _name == THRESHOLD then
    if _param then
      L5_filter.threshold:send("threshold", _param)
    end
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.threshold
  elseif _name == INVERT then
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.invert
  elseif _name == POSTERIZE then
    if _param then
      L5_filter.posterize:send("levels", _param)
    end
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.posterize
  elseif _name == BLUR then
    if _param then
      L5_filter.blur:send("blurSize", _param)
    end
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.blur
  elseif _name == ERODE then
    if _param then
      L5_filter.erode:send("strength", _param)
    end
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.erode
  elseif _name == DILATE then
    if _param then
      L5_filter.dilate:send("strength", _param)
    end
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.dilate
  else
    error("Error: not a filter name.")
  end
end

-- Load pixels from the back buffer into the pixels array
function loadPixels()
    if not L5_env.backBuffer then
        error("L5_env.backBuffer not initialized. Make sure L5 is loaded properly.")
    end
    
    -- Must unbind canvas to call newImageData() on it
    local wasActive = love.graphics.getCanvas() == L5_env.backBuffer
    love.graphics.setCanvas()
    L5_env.imageData = L5_env.backBuffer:newImageData()
    if wasActive then
        love.graphics.setCanvas(L5_env.backBuffer)
    end
    
    local w = L5_env.imageData:getWidth()
    local h = L5_env.imageData:getHeight()
    
    -- Clear the pixels array
    pixels = {}
    
    -- Fill pixels array with RGBA values (0-255 like p5.js)
    -- Index: (x + y * width) * 4
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local r, g, b, a = L5_env.imageData:getPixel(x, y)
            local idx = (x + y * w) * 4
            pixels[idx] = r * 255
            pixels[idx + 1] = g * 255
            pixels[idx + 2] = b * 255
            pixels[idx + 3] = a * 255
        end
    end
    
    L5_env.pixelsLoaded = true  -- Changed from pixelsLoaded to L5_env.pixelsLoaded
end

-- Update the back buffer with modified pixel data
function updatePixels()
    if not L5_env.pixelsLoaded then
        return
    end
    
    local w = L5_env.imageData:getWidth()
    local h = L5_env.imageData:getHeight()
    
    -- Write pixels array back to imageData
    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local idx = (x + y * w) * 4
            local r = (pixels[idx] or 0) / 255  -- Changed from L5_env.pixels to pixels
            local g = (pixels[idx + 1] or 0) / 255
            local b = (pixels[idx + 2] or 0) / 255
            local a = (pixels[idx + 3] or 255) / 255
            L5_env.imageData:setPixel(x, y, r, g, b, a)
        end
    end
    
    -- Create a new image from the modified imageData and draw it to the backBuffer
    local tempImage = love.graphics.newImage(L5_env.imageData)
    local wasActive = love.graphics.getCanvas() == L5_env.backBuffer
    love.graphics.setCanvas(L5_env.backBuffer)
    love.graphics.draw(tempImage, 0, 0)
    if not wasActive then
        love.graphics.setCanvas()
    end
    
    L5_env.pixelsLoaded = false
end

-- Helper function to get pixel index
function getPixelIndex(x, y)
    local w = L5_env.imageData:getWidth()
    return (x + y * w) * 4
end

-- Helper to set a pixel color (optional convenience function)
function setPixel(x, y, r, g, b, a)
    local idx = getPixelIndex(x, y)
    pixels[idx] = r
    pixels[idx + 1] = g
    pixels[idx + 2] = b
    pixels[idx + 3] = a or 255
end

function get(x, y, w, h)
    if not x then
        -- No parameters: return entire window as image
        local wasActive = love.graphics.getCanvas() == L5_env.backBuffer
        love.graphics.setCanvas()
        local imageData = L5_env.backBuffer:newImageData()
        if wasActive then
            love.graphics.setCanvas(L5_env.backBuffer)
        end
        return love.graphics.newImage(imageData)
    elseif not w then
        -- Two parameters: return pixel RGBA (0-255 range)
        local wasActive = love.graphics.getCanvas() == L5_env.backBuffer
        love.graphics.setCanvas()
        local imageData = L5_env.backBuffer:newImageData()
        local r, g, b, a = imageData:getPixel(x, y)
        if wasActive then
            love.graphics.setCanvas(L5_env.backBuffer)
        end
        return r * 255, g * 255, b * 255, a * 255
    else
        -- Four parameters: return sub-region as image
        local wasActive = love.graphics.getCanvas() == L5_env.backBuffer
        love.graphics.setCanvas()
        local fullImageData = L5_env.backBuffer:newImageData()
        
        -- Create a new ImageData for the sub-region
        local subImageData = love.image.newImageData(w, h)
        subImageData:paste(fullImageData, 0, 0, x, y, w, h)
        
        if wasActive then
            love.graphics.setCanvas(L5_env.backBuffer)
        end
        return love.graphics.newImage(subImageData)
    end
end

function set(x, y, c)
    if type(c) == "userdata" and c.type and c:type() == "Image" then
        -- c is an image, draw it at x,y
        local wasActive = love.graphics.getCanvas() == L5_env.backBuffer
        love.graphics.setCanvas(L5_env.backBuffer)
        love.graphics.draw(c, x, y)
        if not wasActive then
            love.graphics.setCanvas()
        end
    elseif type(c) == "table" then
        -- c is a color table {r, g, b, a} (in 0-1 range)
        -- Draw a 1x1 point at x,y with this color
        local wasActive = love.graphics.getCanvas() == L5_env.backBuffer
        love.graphics.setCanvas(L5_env.backBuffer)
        local prevColor = {love.graphics.getColor()}
        love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
        love.graphics.points(x, y)
        love.graphics.setColor(unpack(prevColor))
        if not wasActive then
            love.graphics.setCanvas()
        end
    elseif type(c) == "number" then
        -- c is a grayscale value (0-255)
        local wasActive = love.graphics.getCanvas() == L5_env.backBuffer
        love.graphics.setCanvas(L5_env.backBuffer)
        local prevColor = {love.graphics.getColor()}
        local normalized = c / 255
        love.graphics.setColor(normalized, normalized, normalized, 1)
        love.graphics.points(x, y)
        love.graphics.setColor(unpack(prevColor))
        if not wasActive then
            love.graphics.setCanvas()
        end
    end
end

--- shaders
L5_filter = {}

L5_filter.grayscale = love.graphics.newShader([[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) 
    {
        vec4 pixel = Texel(texture, texture_coords);
        float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114)); // luminance formula
        return vec4(gray, gray, gray, pixel.a) * color;
    }
]])

--from https://www.love2d.org/forums/viewtopic.php?t=3733&start=300, modified to work on Mac
L5_filter.threshold = love.graphics.newShader([[
extern float soft;
extern float threshold;
vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords )
  {
	float f = soft * 0.5;
	float a = threshold - f;
	float b = threshold + f;

	vec4 tx = Texel( texture, texture_coords );
	float l = (tx.r + tx.g + tx.b) * 0.333333;
	vec3 col = vec3( smoothstep(a, b, l) );
	
	return vec4( col, 1.0 ) * color;
  }
]])

-- from https://www.reddit.com/r/love2d/comments/ee8n0j/how_to_make_inverted_colornegative_shader/fcaouw5/
L5_filter.invert = love.graphics.newShader([[ 
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) 
  { 
	vec4 col = Texel( texture, texture_coords ); 
	return vec4(1.0-col.r, 1.0-col.g, 1.0-col.b, col.a) * color; 
  } 
]])

L5_filter.posterize = love.graphics.newShader([[
    uniform float levels; // number of color levels per channel
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        
        // Posterize each color channel
        pixel.r = floor(pixel.r * levels) / levels;
        pixel.g = floor(pixel.g * levels) / levels;
        pixel.b = floor(pixel.b * levels) / levels;
        
        return pixel * color;
    }
]])

L5_filter.blur = love.graphics.newShader([[
  uniform float blurSize;
    uniform vec2 textureSize;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 pixelSize = 1.0 / textureSize;
        vec4 sum = vec4(0.0);
        float totalWeight = 0.0;
        
        // Exponential decay parameter
	// 0.2 to 0.6. lower = more blur. higher = sharper
        float k = 0.4;
        
        // Sample in a circular pattern
	// between 3 - 7. 
	// lower = faster, less smooth. higher=slower, smoother
        int samples = 5;
        for(int x = -samples; x <= samples; x++) {
            for(int y = -samples; y <= samples; y++) {
	        //multiplying blurSize * 2 to aproximate p5's algorithm! not precisely set!
                vec2 offset = vec2(float(x), float(y)) * blurSize * 2 * pixelSize;
                float distance = length(vec2(float(x), float(y)));
                float weight = exp(-k * distance);
                
                sum += Texel(texture, texture_coords + offset) * weight;
                totalWeight += weight;
            }
        }
        
        // Normalize
        sum /= totalWeight;
        
        return sum * color;
    }
]])

L5_filter.erode = love.graphics.newShader([[
    uniform float strength;
    uniform vec2 textureSize;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 pixelSize = 1.0 / textureSize;
        
        vec4 centerColor = Texel(texture, texture_coords);
        vec4 result = centerColor;
        
        // 3x3 erosion - unrolled for Mac compatibility
        vec2 offset;
        vec4 neighborColor;
        
        // Manually unroll the 3x3 kernel (excluding center)
        offset = vec2(-1.0, -1.0) * pixelSize * strength;
        neighborColor = Texel(texture, texture_coords + offset);
        result = mix(result, min(result, neighborColor), 0.3);
        
        offset = vec2(0.0, -1.0) * pixelSize * strength;
        neighborColor = Texel(texture, texture_coords + offset);
        result = mix(result, min(result, neighborColor), 0.3);
        
        offset = vec2(1.0, -1.0) * pixelSize * strength;
        neighborColor = Texel(texture, texture_coords + offset);
        result = mix(result, min(result, neighborColor), 0.3);
        
        offset = vec2(-1.0, 0.0) * pixelSize * strength;
        neighborColor = Texel(texture, texture_coords + offset);
        result = mix(result, min(result, neighborColor), 0.3);
        
        offset = vec2(1.0, 0.0) * pixelSize * strength;
        neighborColor = Texel(texture, texture_coords + offset);
        result = mix(result, min(result, neighborColor), 0.3);
        
        offset = vec2(-1.0, 1.0) * pixelSize * strength;
        neighborColor = Texel(texture, texture_coords + offset);
        result = mix(result, min(result, neighborColor), 0.3);
        
        offset = vec2(0.0, 1.0) * pixelSize * strength;
        neighborColor = Texel(texture, texture_coords + offset);
        result = mix(result, min(result, neighborColor), 0.3);
        
        offset = vec2(1.0, 1.0) * pixelSize * strength;
        neighborColor = Texel(texture, texture_coords + offset);
        result = mix(result, min(result, neighborColor), 0.3);
        
        return result * color;
    }
]])

L5_filter.dilate = love.graphics.newShader([[
    uniform float strength;
    uniform float threshold;
    uniform vec2 textureSize;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 pixelSize = 1.0 / textureSize;
        
        vec4 centerColor = Texel(texture, texture_coords);
        vec4 maxColor = centerColor;
        
        float centerBrightness = dot(centerColor.rgb, vec3(0.299, 0.587, 0.114));
        
        // Only dilate if center pixel is bright enough
        if (centerBrightness > threshold) {
            // Simplified 3x3 dilation instead of 5x5 for Mac compatibility
            vec2 offset;
            vec4 neighborColor;
            float neighborBrightness;
            float weight;
            
            // Unroll 3x3 kernel (excluding center)
            offset = vec2(-1.0, -1.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.414 / (strength + 1.0); // diagonal distance ~1.414
                maxColor = max(maxColor, neighborColor * weight);
            }
            
            offset = vec2(0.0, -1.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.0 / (strength + 1.0);
                maxColor = max(maxColor, neighborColor * weight);
            }
            
            offset = vec2(1.0, -1.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.414 / (strength + 1.0);
                maxColor = max(maxColor, neighborColor * weight);
            }
            
            offset = vec2(-1.0, 0.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.0 / (strength + 1.0);
                maxColor = max(maxColor, neighborColor * weight);
            }
            
            offset = vec2(1.0, 0.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.0 / (strength + 1.0);
                maxColor = max(maxColor, neighborColor * weight);
            }
            
            offset = vec2(-1.0, 1.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.414 / (strength + 1.0);
                maxColor = max(maxColor, neighborColor * weight);
            }
            
            offset = vec2(0.0, 1.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.0 / (strength + 1.0);
                maxColor = max(maxColor, neighborColor * weight);
            }
            
            offset = vec2(1.0, 1.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.414 / (strength + 1.0);
                maxColor = max(maxColor, neighborColor * weight);
            }
        }
        
        return maxColor * color;
    }
]])
