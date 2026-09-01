-- L5 0.2.1 (c) Lee Tusman and Contributors GNU LGPL2.1
VERSION = '0.2.1'

-- Internal table for L5 helper functions
local L5_internal = {} 
-- Internal table for holding state
local L5_env = {} 
-- Internal table for holding filter shaders
local L5_filter = {}
-- Internal table for html color names
local htmlColors = {}

-- Override love.run() - adds double buffering and custom events
function love.run()
  L5_internal.defaults()

  L5_internal.define_env_globals()
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
          if L5_env.filter == "blur_twopass" then
            -- Two-pass blur requires intermediate canvas
            if not L5_env.blurTempCanvas or 
               L5_env.blurTempCanvas:getWidth() ~= love.graphics.getWidth() or
               L5_env.blurTempCanvas:getHeight() ~= love.graphics.getHeight() then
              L5_env.blurTempCanvas = love.graphics.newCanvas()
            end
            
            -- Pass 1: Horizontal blur to temp canvas
            love.graphics.setCanvas(L5_env.blurTempCanvas)
            love.graphics.clear()
            love.graphics.setShader(L5_filter.blur_horizontal)
            love.graphics.draw(L5_env.backBuffer, 0, 0)
            
            -- Pass 2: Vertical blur to screen
            love.graphics.setCanvas()
            love.graphics.setShader(L5_filter.blur_vertical)
            love.graphics.draw(L5_env.blurTempCanvas, 0, 0)
            love.graphics.setShader()
          else
            -- Single-pass filter
            love.graphics.setShader(L5_env.filter)
            love.graphics.draw(L5_env.backBuffer, 0, 0)
            love.graphics.setShader()
          end
          L5_env.filterOn = false
        else
          -- No filter, just draw normally
          love.graphics.draw(L5_env.backBuffer, 0, 0)
        end
        
        -- Restore color (after drawing the canvas)
        love.graphics.setColor(r, g, b, a)

        L5_internal.drawPrintBuffer()

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

  L5_internal.initShaderDefaults()

  stroke(0)
  fill(255)
end

function love.update(dt)
  mouseX, mouseY = love.mouse.getPosition()
  movedX=mouseX-pmouseX
  movedY=mouseY-pmouseY
  deltaTime = dt * 1000
  key = L5_internal.updateLastKeyPressed()

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
function L5_internal.drawPrintBuffer()
    if not L5_env.showPrintBuffer or #L5_env.printBuffer == 0 then
        return
    end
    
    love.graphics.push()
    love.graphics.origin()
    
    -- Save user's current state
    local userFont = love.graphics.getFont()
    local pr, pg, pb, pa = love.graphics.getColor()
    
    love.graphics.setFont(L5_env.printFont or L5_env.defaultFont)
    
    -- Calculate max lines that fit on screen
    local maxLines = math.floor((height - 10) / L5_env.printLineHeight)
    
    -- Trim buffer to only show lines that fit
    local displayBuffer = {}
    local startIdx = math.max(1, #L5_env.printBuffer - maxLines + 1)
    for i = startIdx, #L5_env.printBuffer do
        table.insert(displayBuffer, L5_env.printBuffer[i])
    end
    
    -- Get the font to measure text width
    local font = love.graphics.getFont()
    
    -- Draw each line with its own background
    local y = 5
    for _, line in ipairs(displayBuffer) do
        local textWidth = font:getWidth(line)
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle('fill', 5, y, textWidth + 4, L5_env.printLineHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(line, 5, y)
        y = y + L5_env.printLineHeight
    end
    
    -- Restore user's state
    love.graphics.setFont(userFont)
    love.graphics.setColor(pr, pg, pb, pa)
    
    love.graphics.pop()
end

--- API Start
---
--- ANNOTATION ALIASES
---@alias Image userdata|table An image object returned by loadImage(), or an offscreen buffer from createGraphics. Internally a LÖVE Image (userdata)
---@alias Font userdata A font object returned by loadFont()
---@alias Video table A video object returned by loadVideo(), wrapping a LÖVE Video with play(), pause(), stop(), loop(), noLoop(), time(), and volume() methods

---Enables the on-screen print console and sets its font size.
---@param textSize? number Font size in points (default: 16)
function printToScreen(textSize)
  L5_env.showPrintBuffer = true

  textSize = textSize or 16  
    
  L5_env.printFont = love.graphics.newFont(textSize)
  L5_env.printLineHeight = L5_env.printFont:getHeight()

end

---Sets the window size.
---@param _w number Window width, in pixels
---@param _h number Window height, in pixels
function size(_w, _h)
  -- do nothing if the window size hasn't changed
  if _w == width and _h == height then return end
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

---Switches to fullscreen, optionally on a specific display.
---@param display? integer Display index to use, 1-based (default: 1)
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

--internal helper function hex code to RGB value
local function hexToRGB(hex)
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

--internal helper function HSV to RGB
local function HSVtoRGB(h, s, v)  
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

--internal helper function for HSL (hue, saturation, and lightness) to RGB value
local function HSLtoRGB(h, s, l)
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

--internal helper function for converting RGB to HSL 
local function RGBtoHSL(r, g, b)
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

--internal helper function for color handling
local function toColor(_a, _b, _c, _d)
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

---Saves a screenshot of the display window as a PNG file.
---Tries to save to the same folder as your project first; if that fails (e.g. in a packaged app), it falls back to LÖVE's save directory instead. Check console output to see exactly where the file is written.
---@param filename? string Optional filename; .png is appended automatically if omitted. Default: screenshot_<timestamp>.png
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

---Prints an accessibility description to the command line. 
---@param sceneDescription string Text describing the current scene
function describe(sceneDescription)
  L5_env.originalPrint("CANVAS_DESCRIPTION: " .. sceneDescription)
  io.flush() -- Ensure immediate output for screen readers
end

--declares global variables that are user-accessible
function L5_internal.defaults()
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
  CLOSE = "close"
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
  -- beginShape kinds
  POINTS = "points"
  LINES = "lines"
  TRIANGLES = "triangles"
  TRIANGLE_FAN = "fan"
  TRIANGLE_STRIP = "strip"

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
function L5_internal.define_env_globals()
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
  -- global video tracking for looping
  L5_env.videos = {}
  -- global font state
  L5_env.fontPaths = {}
  L5_env.currentFontPath = nil
  L5_env.currentFontSize = love.graphics.getFont():getHeight()
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
  L5_env.kind = nil
  L5_env.shapeKinds = {[POINTS] = true, [LINES] = true, [TRIANGLES]=true, [TRIANGLE_FAN]=true, [TRIANGLE_STRIP]=true}
  L5_env.mesh = love.graphics.newMesh(
    {{"VertexPosition", "float", 2}},
    4096, "triangles", "dynamic"
  ) -- reusable mesh for non-texture shapes
  -- custom texture mesh
  L5_env.currentTexture = nil
  L5_env.useTexture = false
  L5_env.textureMode=IMAGE -- NORMAL or IMAGE
  L5_env.textureWrap=CLAMP -- wrap mode CLAMP or REPEAT
  -- custom print output on screen
  L5_env.printBuffer = {}
  L5_env.defaultFont = love.graphics.getFont()
  L5_env.printFont = L5_env.defaultFont
  L5_env.showPrintBuffer = false  
  L5_env.printY = 5
  L5_env.printLineHeight = L5_env.defaultFont:getHeight() + 2
  -- style stack for push()/pop() — tracks L5_env fields not covered by LOVE's built-in love.graphics.push/pop
  L5_env.styleStack = {}
    
    -- Override print to also draw to screen
  local originalPrint = print
  L5_env.originalPrint = originalPrint
  function print(...)
    originalPrint(...)  -- Still print to console
    
    local text = ""
    local args = {...}
    for i = 1, #args do
        if i > 1 then text = text .. "\t" end
        text = text .. tostring(args[i])
    end
    
    table.insert(L5_env.printBuffer, text)
  end
end

------------------ INIT SHADERS ---------------------
-- initialize shader default values
function L5_internal.initShaderDefaults()
    -- Set default values for threshold shader
    L5_filter.threshold:send("soft", 0.5)
    L5_filter.threshold:send("threshold", 0.5)
    
    -- Set default value for posterize
    L5_filter.posterize:send("levels", 4.0)
    -- Set default values for blur
if L5_filter.blurSupportsParameter then
    L5_filter.blur_horizontal:send("blurRadius", 4.0)
    L5_filter.blur_horizontal:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    L5_filter.blur_vertical:send("blurRadius", 4.0)
    L5_filter.blur_vertical:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
elseif L5_filter.blur then
    L5_filter.blur:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
end
    -- Set default values for erode
    L5_filter.erode:send("strength", 0.5)
    L5_filter.erode:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
    
    -- Set default values for dilate
    L5_filter.dilate:send("strength", 1.0)
    L5_filter.dilate:send("threshold", 0.1)
    L5_filter.dilate:send("textureSize", {love.graphics.getWidth(), love.graphics.getHeight()})
end

----------------------- INPUT -----------------------

---Loads a text file and returns a table
---@param _file string The path to the file. Paths to local files should be relative.
function loadStrings(_file)
  local lines = {} 
  for line in love.filesystem.lines(_file) do 
    table.insert(lines, line)
  end
  return lines
end

---Reads the contents of a file and creates a table object with its values. 
---The file's path should be specified relative to the sketch's folder. 
---The file format can be a comma-separated (in CSV format), a tab-separated value (in TSV format), or a lua table (as a lua file). 
---Table only looks for a header row if the 'header' option is included.
---@param _file string The path to the file. Paths to local files should be relative.
---@param _header? string Optional string 'header' indicates a header row is included
---@return table data For CSV/TSV: array of rows (or records, if "header" used), plus a `.columns` field listing column names/indices. For .lua files: whatever table the file itself returns.
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

---Saves an array table to a file, one entry per line.
---Writes to the current directory. Fails if the location is not writable — check the return value or console output.
---@param data table An array (ordered table) of values to save, one per line
---@param filename string The filename to save to
---@return boolean success `true` if the file was written; `false` if it failed
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

---Writes the contents of a table to a file, either comma-separated-values ('csv'), tab-separated values ('tsv'), or a Lua table ('lua', default). If format is omitted, it's inferred.
---@param data table A table to save (array or table with named keys)
---@param filename string The filename to save to
---@param format? "lua"|"csv"|"tsv" Optional explicit selection of data format; otherwise format is determined by filename extension 
---@return boolean success `true` if the file was written; `false` if it failed or format is not supported
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

--internal tracking of keys
function L5_internal.updateLastKeyPressed()
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

---Returns true if the given key is currently pressed. Useful for checking multiple keys at once, e.g. left arrow and up arrow together for diagonal movement.
---@param k string The key to check, e.g. "left", "up", "space", "w"
---@return boolean isDown
function keyIsDown(k)
  return L5_env.pressedKeys[k] == true
end

---------------------- TRANSFORM ---------------------

--internal helper function for copying style for use with push()/pop() 
function L5_internal.copyStyle(t)
  local out = {}
  for k, v in pairs(t) do
    out[k] = v
  end
  return out
end

---Begins a drawing group that contains its own style and transformations.
---By default, styles such as fill() and transformations such as rotate() are applied to all drawing that follows. The push() and pop() functions can limit the effect of styles and transformations to a specific group of shapes, images, and text.
---@see pop
function push()
  local STYLE_KEYS = {
    "fill_mode",
    "stroke_color",
    "currentTint",
    "image_mode",
    "rect_mode",
    "ellipse_mode",
    "color_mode",
    "color_max",
    "textAlignX",
    "textAlignY",
    "currentFontPath",
    "currentFontSize",
    "currentFont"
  }

    love.graphics.push('all')
  local snapshot = {}
  for _, k in ipairs(STYLE_KEYS) do
    local v = L5_env[k]
    snapshot[k] = (type(v) == "table") and L5_internal.copyStyle(v) or v
  end
  table.insert(L5_env.styleStack, snapshot)
end

---Ends a drawing group that contains its own style and transformations.
---By default, styles such as fill() and transformations such as rotate() are applied to all drawing that follows. The push() and pop() functions can limit the effect of styles and transformations to a specific group of shapes, images, and text.
---@see push
function pop()
  love.graphics.pop('all')
  local snapshot = table.remove(L5_env.styleStack)
  if snapshot then
    for k, v in pairs(snapshot) do
      L5_env[k] = v
    end
  end
end

---Translates the coordinate system.
---By default, the origin (0, 0) is at the sketch's top-left corner in 2D. The translate() function shifts the origin to a different position. Everything drawn after translate() is called will appear to be shifted.
---By default, transformations accumulate. Note: Transformations are reset at the beginning of the draw loop.
---@param _x number Amount to translate along the positive x-axis.
---@param _y number Amount to translate along the positive y-axis.
function translate(_x,_y)
  love.graphics.translate(_x,_y )
end

---Rotates the coordinate system.
---By default, the positive x-axis points to the right and the positive y-axis points downward. The rotate() function changes this orientation by rotating the coordinate system about the origin. Everything drawn after rotate() is called will appear to be rotated.
---Note: Transformations are reset at the beginning of the draw loop. Calling rotate(1) inside the draw() function won't cause shapes to spin
---@param _angle number Amount to rotate along the positive x-axis, specified in radians (default) or degrees if set by angleMode()
function rotate(_angle)
  if L5_env.degree_mode == RADIANS then 
    love.graphics.rotate(_angle)
  else
    love.graphics.rotate(radians(_angle))
  end
end

---Scales the coordinate system.
---By default, shapes are drawn at their original scale. The scale() function can shrink or stretch the coordinate system so that shapes appear at different sizes. 
---By default, transformations accumulate. Calling scale(2) twice has the same effect as calling scale(4) once. The push() and pop() functions can be used to isolate transformations within distinct drawing groups.
---@param _sx number Amount to scale along the positive x-axis.
---@param _sy? number Amount to scale along the positive y-axis. If omitted will default to the set scale along the x-axis.
function scale(_sx,_sy)
  if _sy ~= nil then --2 args, 2 dif scales
    love.graphics.scale(_sx,_sy)
  else --only 1 arg, scale same both directions
    love.graphics.scale(_sx,_sx)
  end
end

---Applies a transformation matrix (of 6 values) to the coordinate system.
---applyMatrix() allows for many transformations to be applied at once. 
---By default, transformations accumulate. The push() and pop() functions can be used to isolate transformations within distinct drawing groups. Note: Transformations are reset at the beginning of the draw loop.
---@overload fun(a: number, b: number, c: number, d: number, e: number, f: number)
---@overload fun(matrix: table) A table of 6 numbers: {a, b, c, d, e, f}
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

---Clears all transformations applied to the coordinate system.
function resetMatrix()
  love.graphics.origin()
end

-------------------- TIME and DATE -------------------

---Returns the number of milliseconds since a sketch started running.
---@return number millis
function millis()
  return 1000*love.timer.getTime()
end

---Returns the current day as a number from 1–31.
---@return number day
function day()
  return tonumber(os.date("%d"))
end

---Returns the current month as a number from 1–12.
---@return number month
function month()
  return tonumber(os.date("%m"))
end

---Returns the current year as a number such as 1999.
---@return number year
function year()
  return tonumber(os.date("%Y"))
end

---Returns the current hour as a number 0-23.
---@return number hour
function hour()
  return tonumber(os.date("%H"))
end

---Returns the current minute as a number 0-59.
---@return number minute
function minute()
  return tonumber(os.date("%M"))
end

---Returns the current second as a number 0-59.
---@return number second
function second()
  return tonumber(os.date("%S"))
end

------------------------ SHAPE -----------------------

-------------------- 2D Primitives -------------------

---Draws a rectangle. The meaning of the four position/size parameters depends on the current rectMode() setting.
---Default (CORNER): _a,_b is the top-left corner; _c,_d is width and height.
---CORNERS: _a,_b and _c,_d are two opposite corners.
---CENTER: _a,_b is the center; _c,_d is width and height.
---RADIUS: _a,_b is the center; _c,_d are the horizontal and vertical radius.
---@param _a number X-coordinate 
---@param _b number Y-coordinate 
---@param _c number The width, second corner's x, or horizontal radius, depending on rectMode
---@param _d number The height, second corner's y, or vertical radius, depending on rectMode()
---@param _e? number Optional corner radius for rounded corners
---@see rectMode
function rect(_a,_b,_c,_d,_e)
  if not _d then
    _d = _c
  end
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

---Draws a square. Parameter meaning depends on the current rectMode(). (CORNERS mode is not supported for squares, displays error if active.)
---Default (CORNER): _a,_b is top-left corner; _c is width and height
---CENTER: _a,_b is the center; _c is width and height.
---RADIUS: _a,_b is the center; _c is the radius (half the length).
---@param _a number X-coordinate 
---@param _b number Y-coordinate 
---@param _c number Width and height or radius, depending on rectMode
---@param _d? number Optional corner radius for rounded corners (not height)
---@see rectMode
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
  elseif L5_env.rect_mode == CORNERS then
    error("square() does not support CORNERS mode; use rect() instead")
  end
end

---Draws an ellipse (oval). Parameter meaning depends on ellipseMode() (default: CENTER):
---CENTER: _a,_b center; _c,_d width, height.
---RADIUS: _a,_b center; _c,_d horizontal, vertical radius.
---CORNER: _a,_b top-left corner; _c,_d width, height.
---CORNERS: _a,_b and _c,_d are two opposite corners.
---@param _a number
---@param _b number
---@param _c number
---@param _d? number Height, radius, or second corner's y — depending on mode. Defaults to _c if omitted (draws a circle)
---@see ellipseMode
function ellipse(_a,_b,_c,_d)
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
    love.graphics.ellipse(L5_env.fill_mode,_a+(_c-_a)/2,_b+(_d-_b)/2,(_c-_a)/2,(_d-_b)/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a+(_c-_a)/2,_b+(_d-_b)/2,(_c-_a)/2,(_d-_b)/2)
    love.graphics.setColor(r, g, b, a)
  else --default CENTER x,y,w/2,h/2
    love.graphics.ellipse(L5_env.fill_mode,_a,_b,_c/2,_d/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  end
end

---Draws a circle. Parameter meaning depends on ellipseMode() (default: CENTER; CORNERS mode is not supported — errors if active):
---CENTER: _a,_b center; _c diameter.
---RADIUS: _a,_b center; _c radius.
---CORNER: _a,_b top-left corner; _c diameter.
---@param _a number
---@param _b number
---@param _c number
---@see ellipseMode
function circle(_a,_b,_c)
  if L5_env.ellipse_mode==RADIUS then 
    love.graphics.ellipse(L5_env.fill_mode,_a,_b,_c,_c) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c,_c)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.ellipse_mode==CORNER then 
    love.graphics.ellipse(L5_env.fill_mode,_a+_c/2,_b+_c/2,_c/2,_c/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a+_c/2,_b+_c/2,_c/2,_c/2)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.ellipse_mode==CORNERS then 
    error("circle() does not support CORNERS mode; use ellipse() instead")
  elseif L5_env.ellipse_mode==CENTER then --default CENTER x,y,w/2,h/2
    love.graphics.ellipse(L5_env.fill_mode,_a,_b,_c/2,_c/2) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.ellipse("line",_a,_b,_c/2,_c/2)
    love.graphics.setColor(r, g, b, a)
  end
end

---Draws a quadrilateral (4-sided polygon) from four corner points, in order.
---@type fun(_x1: number, _y1: number, _x2: number, _y2: number, _x3: number, _y3: number, _x4: number, _y4: number)
function quad(_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) --this is a 4-sided love2d polygon! 
  --for other # of sides, use processing api call createShape
  love.graphics.polygon(L5_env.fill_mode,_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
    love.graphics.setColor(r, g, b, a)
end

---Draws a triangle (3-sided polygon) from three corner points, in order.
---@type fun(_x1: number, _y1: number, _x2: number, _y2: number, _x3: number, _y3: number)
function triangle(_x1,_y1,_x2,_y2,_x3,_y3) --this is a 3-sided love2d polygon
  love.graphics.polygon(L5_env.fill_mode,_x1,_y1,_x2,_y2,_x3,_y3) 
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3)
    love.graphics.setColor(r, g, b, a)
end

-- Helper function to draw elliptical arcs
local function draw_elliptical_arc(cx, cy, rx, ry, start_angle, arc_span, arctype)
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

---Draws an arc, a section of an ellipse defined by the x, y, w, and h parameters, and optional mode.
---@param _x number X-coordinate of the arc's ellipse, affected by ellipseMode()
---@param _y number Y-coordinate of the arc's ellipse, affected by ellipseMode()
---@param _w number Width of the arc's ellipse, affected by ellipseMode()
---@param _h number Height of the arc's ellipse, affected by ellipseMode()
---@param _start number Angle to start the arc, in degrees or radians depending on angleMode()
---@param _stop number Angle to stop the arc, always drawn clockwise from start to stop.
---@param _arctype? OPEN|CLOSED|PIE Fill style: OPEN (semi-circle), CHORD (closed semi-circle), or PIE (closed pie segment).
---@see ellipseMode
---@see angleMode
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

---Draws a single point in space. Default width is one pixel.
---To color a point, use the stroke() function. To change its width, use strokeWeight()
---@param _x number X-coordinate of the point
---@param _y number Y-coordinate of the point
---@see stroke
---@see strokeWeight
function point(_x,_y)
  --Points unaffected by love.graphics.scale - size is always in pixels
  --a line is drawn in the stroke color
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(unpack(L5_env.stroke_color)) 
  love.graphics.points(_x,_y)
  love.graphics.setColor(r, g, b, a)
end

---Draws a straight line between two points. Default width is one pixel.
---To color a line, use the stroke() function. To change its width, use strokeWeight()
---@param _x1 number X-coordinate of the line starting point
---@param _y1 number Y-coordinate of the line starting point
---@param _x2 number X-coordinate of the line ending point
---@param _y2 number Y-coordinate of the line ending point
---@see stroke
---@see strokeWeight
function line(_x1,_y1,_x2,_y2)
  --a line is drawn in the stroke color
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color)) 
    love.graphics.line(_x1,_y1,_x2,_y2)
    love.graphics.setColor(r, g, b, a)
end

---Sets the current background color (values are 0-255) or image
---@overload fun(img: Image) An image previously loaded with loadImage()
---@overload fun(gray: number)
---@overload fun(gray: number, alpha: number)
---@overload fun(r: number, g: number, b: number)
---@overload fun(r: number, g: number, b: number, a: number)
---@overload fun(colorName: string)
---@overload fun(hex: string)
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

---Changes the way color values are interpreted. Specify RGB, HSB, or HSL mode and (optionally) parameter maximum.
---By default, the Number parameters for fill(), stroke(), background(), and color() are defined by values between 0 and 255 using the RGB color model.
---@overload fun(_mode: string) Specify RGB, HSB, or HSL mode.
---@overload fun(_mode: string, _max: number) Sets the max value for all channels/attributes
---@overload fun(_mode: string, _max1: number, _max2: number, _max3: number) Sets max values for each channel/attribute (excludes alpha, defaults to 255 or 100)
---@overload fun(_mode: string, _max1: number, _max2: number, _max3: number, _maxA: number) Sets max values for each channel/attribute, including alpha
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

---Sets the current fill color (values are 0-255).
---The version of fill() with three parameters interprets them as RGB, HSB, or HSL colors, depending on the current colorMode(). The default color space is RGB, with each value in the range from 0 to 255.
---@overload fun(gray: number)
---@overload fun(gray: number, alpha: number)
---@overload fun(r: number, g: number, b: number)
---@overload fun(r: number, g: number, b: number, a: number)
---@overload fun(colorName: string)
---@overload fun(hex: string)
---@overload fun(colors: table) A table of {r, g, b} or {r, g, b, a} values, 0-255
---@see colorMode
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

---Creates a color object.
---By default, the parameters are interpreted as RGB values. The way these parameters are interpreted may be changed with the colorMode() function.
---@overload fun(gray: number)
---@overload fun(gray: number, alpha: number)
---@overload fun(r: number, g: number, b: number)
---@overload fun(r: number, g: number, b: number, a: number)
---@overload fun(colorName: string)
---@overload fun(hex: string)
---@overload fun(colors: table) A table of {r, g, b} or {r, g, b, a} values, 0-255
---@return table color Returns normalized RGBA values (0-1 range), e.g. {r, g, b, a}
---@see colorMode
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

---Extracts the red value from a color.
---@param _color table|string A color table (e.g. from color()) or a CSS color string
---@return number red Red channel value, scaled to the current colorMode() range, default 0-255
---@see colorMode
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

---Extracts the green value from a color.
---@param _color table|string A color table (e.g. from color()) or a CSS color string
---@return number green Green channel value, scaled to the current colorMode() range, default 0-255
---@see colorMode
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

---Extracts the blue value from a color.
---@param _color table|string A color table (e.g. from color()) or a CSS color string
---@return number blue Blue channel value, scaled to the current colorMode() range, default 0-255
---@see colorMode
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

---Extracts the alpha channel value from a color.
---@param _color table|string A color table (e.g. from color()) or a CSS color string
---@return number alpha Alpha channel value, scaled to the current colorMode() range (default 0-255 in RGB mode)
---@see colorMode
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

---Gets the brightness value of a color (HSB "V"/value component) 
---By default, brightness() returns a color's HSB brightness in the range 0 to 100. If the colorMode() is set to HSB, it returns the brightness value in the given range.
---@param _color table|string A color table (e.g. from color()) or a CSS color string
---@return number brightness Brightness value: scaled to the current colorMode() range in HSB mode, otherwise 0-100
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

---Gets the lightness value of a color.
---lightness() extracts the HSL lightness value from a color object, an array of color components, or a CSS color string.
---@param _color table|string A color table (e.g. from color()) or a CSS color string
---@return number lightness Lightness value: scaled to the current colorMode() range in HSL mode, otherwise 0-100
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

---Gets the hue value of a color.
---hue() extracts the hue value from a color object, an array of color components, or a CSS color string.
---Hue describes a color's position on the color wheel. By default, hue() returns a color's HSL hue in the range 0 to 360. If the colorMode() is set to HSB or HSL, it returns the hue value in the given mode.
---@param _color table|string A color table (e.g. from color()) or a CSS color string
---@return number hue Hue value: scaled to the current colorMode() range in HSB/HSL mode, defaults to 0-360
---@see colorMode
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

---Blends two colors to find a third color between them.
---Color interpolation depends on current colorMode()
---@param _c1 table|string First color (a color table or CSS color string)
---@param _c2 table|string Second color (a color table or CSS color string)
---@param _amt number Amount to interpolate between the two colors. 0 is equal to the first color, 0.5 is halfway and 1 is the second color. Numbers out of range are constrained to 0 or 1.
---@return table color The interpolated color, e.g. {r, g, b, a}
---@see colorMode
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

---Modifies the location from which rectangles are drawn by changing the way in which parameters given to rect() are interpreted.
---By default, the first two parameters of a rectangle are the x- and y-coordinates of its top left corner, the same as calling rectMode(CORNER)
---@param _mode string Either CORNER (default), CORNERS, CENTER, or RADIUS
function rectMode(_mode)
  if _mode == CORNER or _mode == CORNERS or _mode == CENTER or _mode == RADIUS then
    L5_env.rect_mode = _mode
  else
    error("rectMode() must be CORNER, CORNERS, CENTER, or RADIUS")
  end
end

---Modifies the location from which ellipses, circles, and arcs are drawn.
---By default, the first two parameters of a circle are the x- and y-coordinates of its center, the same as calling ellipseMode(CENTER)
---@param _mode string Either CENTER (default), CORNER, CORNERS or RADIUS
function ellipseMode(_mode)
  if _mode == CENTER or _mode == CORNER or _mode == CORNERS or _mode == RADIUS then
    L5_env.ellipse_mode = _mode
  else
    error("ellipseMode() must be CENTER, CORNER, CORNERS, or RADIUS")
  end
end

---Modifies the location from which images are drawn when image() is called.
---By default, the first two parameters of image() are the x- and y-coordinates of the image's upper-left corner. This is the same as calling imageMode(CORNER).
---@param _mode string Either CORNER (default), CENTER or CORNERS
function imageMode(_mode)
  if _mode == CORNER or _mode == CENTER or _mode == CORNERS then
    L5_env.image_mode = _mode
  else
    error("imageMode() must be CORNER, CENTER, or CORNERS")
  end
end

---Disables the fill color for shapes
---Calling noFill() is the same as making the fill completely transparent, as in fill(0, 0). If both noStroke() and noFill() are called, nothing will be drawn to the screen.
function noFill()
  L5_env.fill_mode="line" 
end

---Sets the width of the stroke used for lines, points, and the border around shapes. All widths are set in units of pixels.
---Using point() with strokeWeight(1) or smaller may draw nothing to the screen, depending on the graphics settings of the computer. Workarounds include drawing the point using either circle() or square().
---@param _w number Stroke width in pixels
function strokeWeight(_w)
  love.graphics.setLineWidth(_w)
  love.graphics.setPointSize(_w) --also sets sizing on points
end

---Sets the style of the joints that connect line segments.
---@param _style string Either MITER (default), BEVEL, or NONE
function strokeJoin(_style)
  if _style == MITER or _style == BEVEL or _style == NONE then
    love.graphics.setLineJoin(_style)
  else
    error("strokeJoin() must be either MITER, BEVEL or NONE")
  end
end

---Draws features with jagged (aliased) edges.
---smooth() is active by default. The functions don't affect shapes or fonts.
---@see smooth
function noSmooth()
  love.graphics.setDefaultFilter("nearest", "nearest", 1)
  love.graphics.setLineStyle('rough')
end

---Draws features with smooth (anti-aliased) edges.
---smooth() is active by default. The functions don't affect shapes or fonts.
---@see noSmooth
function smooth()
  love.graphics.setDefaultFilter("linear", "linear", 1)
  love.graphics.setLineStyle('smooth')
end

---Sets the color used to draw points, lines, and the outlines of shapes.
---The version of stroke() with three parameters interprets them as RGB, HSB, or HSL colors, depending on the current colorMode(). The default color space is RGB, with each value in the range from 0 to 255.
---@overload fun(gray: number)
---@overload fun(gray: number, alpha: number)
---@overload fun(r: number, g: number, b: number)
---@overload fun(r: number, g: number, b: number, a: number)
---@overload fun(colorName: string)
---@overload fun(hex: string)
---@overload fun(colors: table) A table of {r, g, b} or {r, g, b, a} values, 0-255
function stroke(...)
  local args = {...}
  
  -- If single argument is a table
  if #args == 1 and type(args[1]) == "table" then
    local t = args[1]
    -- Check if it's normalized (all values <= 1.0) or raw array
    if t[1] <= 1.0 and t[2] <= 1.0 and t[3] <= 1.0 and (not t[4] or t[4] <= 1.0) then
      -- Already normalized, use directly
      L5_env.stroke_color = t
    else
      -- Raw array, needs conversion
      L5_env.stroke_color = toColor(unpack(t))
    end
  else
    L5_env.stroke_color = toColor(...)
  end
end

---Disables drawing points, lines, and the outlines of shapes.
---Calling noStroke() is the same as making the stroke completely transparent, as in stroke(0, 0). If both noStroke() and noFill() are called, nothing will be drawn to the screen.
function noStroke()
  L5_env.stroke_color={0,0,0,0} 
end

------------------ RENDERING ------------------------

---Creates an offscreen canvas with specified dimensions that can be rendered to the window later.
---Begin drawing to this graphics buffer with :beginDraw()
---End drawing to this graphics buffer with :endDraw()
---Draw to screen with image(). 
---Example: offscreenCanvas = createGraphics(width,height)
---offscreenCanvas:beginDraw()
---circle(100,100,30)
---offscreenCanvas:endDraw()
---image(offscreenCanvas:getCanvas(),0,0)
---@param _width number Offscreen canvas width, in pixels
---@param _height number Offscreen canvas height, in pixels
---@return table graphics An offscreen graphics buffer with beginDraw(), endDraw() and getCanvas() methods
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

---Sets a texture to be applied to vertex points. 
---@param _img Image Texture to be applied
function texture(_img)
  -- Allow passing a createGraphics() buffer directly, without needing :getCanvas()
  if type(_img) == "table" and _img._canvas then
    _img = _img._canvas
  end

  -- to be applied to vertices
  L5_env.currentTexture = _img
  L5_env.useTexture = true
end

---Changes the coordinate system used for textures when they’re applied to custom shapes. 
---The default mode is IMAGE, which refers to the actual coordinates of the image in pixels. NORMAL refers to a normalized space of values ranging from 0 to 1.
---@param _mode string IMAGE (default) or NORMAL 
---@see vertex
function textureMode(_mode)
    -- Set how texture coordinates are interpreted
    -- NORMAL - coordinates are 0 to 1
    -- IMAGE - coordinates are in pixel dimensions
    if _mode == NORMAL or _mode == IMAGE then
        L5_env.textureMode = _mode
    else
        error("textureMode must be NORMAL or IMAGE")
    end
end

---Defines if textures repeat or draw once within a texture map. 
---The two parameters are CLAMP (the default behavior) and REPEAT.  
---@param _mode string CLAMP (default) or REPEAT 
---@see texture
function textureWrap(_mode)
    -- Set texture wrapping mode
    -- Valid modes: CLAMP or REPEAT
    if _mode == CLAMP or _mode == REPEAT then
      L5_env.textureWrap = _mode
    else
      error("textureWrap must be CLAMP or REPEAT")
    end
end

---beginShape() begins adding vertices to a custom shape. 
---Default shape is an irregular polygon. The optional mode parameter can be POINTS, LINES, TRIANGLES, TRIANGLE_FAN, TRIANGLE_STRIP
---@param _kind? string Optional shape mode: POINTS, LINES, TRIANGLES, TRIANGLE_FAN, TRIANGLE_STRIP
---@see endShape
function beginShape(...)

  local n = select('#' , ...)
  if(n > 1) then
     error("beginShape(kind) accepts at most one argument", 2)
  end

  local _kind = select(1, ...)

  if n == 0 then
    _kind = nil
  elseif _kind == nil then
    error("This kind is not defined (undefined variable passed)")
  elseif not L5_env.shapeKinds[_kind] then -- if any other type is passed
    error("Invalid kind: " .. tostring(_kind))
  end

  -- reset custom shape vertices table
  L5_env.vertices = {}
  L5_env.useTexture = false
  L5_env.kind = _kind
end

---Adds a vertex to a custom shape.
---@param _x number x-coordinate to add to current custom shape
---@param _y number y-coordinate to add to current custom shape
---@param _u? number u coordinate for an applied texture (default IMAGE, set with textureMode)
---@param _v? number v coordinate for an applied texture  (default IMAGE mode, set with textureMode)
---@see textureMode
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

---endShape() ends adding vertices to a custom shape and draws it to the screen. 
---@param _close? string Optionally add CLOSE to connect final vertex back to the first for polygons.
---@see beginShape
function endShape(_close)
  -- no vertices, early exit
  if #L5_env.vertices == 0 then return end

  -- helper function to convert flat {x,y,x,y...} to {{x,y},{x,y}...}
  local function toVertTable(verts)
    if type(verts[1]) == "number" then
      local converted = {}
      for i = 1, #verts, 2 do
        converted[#converted+1] = {verts[i], verts[i+1]}
      end
      return converted
    end
    return verts
  end

  -- draw points
  if L5_env.kind == POINTS then
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color))
    for i = 1, #L5_env.vertices, 2 do
      love.graphics.points(L5_env.vertices[i], L5_env.vertices[i+1])
    end
    love.graphics.setColor(r, g, b, a)

  -- draw unconnected lines
  elseif L5_env.kind == LINES then
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color))
    for i = 1, #L5_env.vertices - 2, 4 do
      love.graphics.line(
        L5_env.vertices[i], L5_env.vertices[i+1],
        L5_env.vertices[i+2], L5_env.vertices[i+3]
      )
    end
    love.graphics.setColor(r, g, b, a)

  -- draw separated triangles
  elseif L5_env.kind == TRIANGLES then
    local verts = toVertTable(L5_env.vertices)
    if L5_env.useTexture and L5_env.currentTexture then
      local mesh = love.graphics.newMesh(verts, TRIANGLES)
      mesh:setTexture(L5_env.currentTexture)
      L5_env.currentTexture:setWrap(L5_env.textureWrap, L5_env.textureWrap)
      love.graphics.draw(mesh)
    else
      if L5_env.fill_mode == "fill" then
        L5_env.mesh:setVertices(verts, 1, #verts)
        L5_env.mesh:setDrawMode("triangles")
        L5_env.mesh:setDrawRange(1, #verts)
        love.graphics.draw(L5_env.mesh)
      end
      local r, g, b, a = love.graphics.getColor()
      love.graphics.setColor(unpack(L5_env.stroke_color))
      for i = 1, #verts, 3 do
        local v1, v2, v3 = verts[i], verts[i+1], verts[i+2]
        if v1 == nil or v2 == nil or v3 == nil then break end
        love.graphics.line(v1[1],v1[2], v2[1],v2[2])
        love.graphics.line(v2[1],v2[2], v3[1],v3[2])
        love.graphics.line(v3[1],v3[2], v1[1],v1[2])
      end
      love.graphics.setColor(r, g, b, a)
    end

  -- draw triangle strip
  elseif L5_env.kind == TRIANGLE_STRIP then
    local verts = toVertTable(L5_env.vertices)
    if L5_env.useTexture and L5_env.currentTexture then
      local mesh = love.graphics.newMesh(verts, TRIANGLE_STRIP)
      mesh:setTexture(L5_env.currentTexture)
      L5_env.currentTexture:setWrap(L5_env.textureWrap, L5_env.textureWrap)
      love.graphics.draw(mesh)
    else
      if L5_env.fill_mode == "fill" then
        L5_env.mesh:setVertices(verts, 1, #verts)
        L5_env.mesh:setDrawMode("strip")
        L5_env.mesh:setDrawRange(1, #verts)
        love.graphics.draw(L5_env.mesh)
      end
      local r, g, b, a = love.graphics.getColor()
      love.graphics.setColor(unpack(L5_env.stroke_color))
      for i = 1, #verts-2 do
        local v1, v2, v3 = verts[i], verts[i+1], verts[i+2]
        if v1 == nil or v2 == nil or v3 == nil then break end
        love.graphics.line(v1[1],v1[2], v2[1],v2[2])
        love.graphics.line(v2[1],v2[2], v3[1],v3[2])
        love.graphics.line(v3[1],v3[2], v1[1],v1[2])
      end
      love.graphics.setColor(r, g, b, a)
    end

  -- draw triangles centered around the first vertex
  elseif L5_env.kind == TRIANGLE_FAN then
    local verts = toVertTable(L5_env.vertices)
    if L5_env.useTexture and L5_env.currentTexture then
      local mesh = love.graphics.newMesh(verts, TRIANGLE_FAN)
      mesh:setTexture(L5_env.currentTexture)
      L5_env.currentTexture:setWrap(L5_env.textureWrap, L5_env.textureWrap)
      love.graphics.draw(mesh)
    else
      if L5_env.fill_mode == "fill" then
        L5_env.mesh:setVertices(verts, 1, #verts)
        L5_env.mesh:setDrawMode("fan")
        L5_env.mesh:setDrawRange(1, #verts)
        love.graphics.draw(L5_env.mesh)
      end
      local r, g, b, a = love.graphics.getColor()
      love.graphics.setColor(unpack(L5_env.stroke_color))
      for i = 2, #verts-1 do
        local v1, v2, v3 = verts[1], verts[i], verts[i+1]
        if v1 == nil or v2 == nil or v3 == nil then break end
        love.graphics.line(v1[1],v1[2], v2[1],v2[2])
        love.graphics.line(v2[1],v2[2], v3[1],v3[2])
        love.graphics.line(v3[1],v3[2], v1[1],v1[2])
      end
      love.graphics.setColor(r, g, b, a)
    end

  -- polygon fallback (kind == nil) 
  -- if texture() triangulate fan mesh - convex assumed
  else
    if L5_env.useTexture and L5_env.currentTexture then
      local mesh = love.graphics.newMesh(L5_env.vertices, "fan")
      mesh:setTexture(L5_env.currentTexture)
      L5_env.currentTexture:setWrap(L5_env.textureWrap, L5_env.textureWrap)
      love.graphics.draw(mesh)
    else
      -- triangulate handles concave shapes but errors on self-intersecting polygons
      if L5_env.fill_mode == "fill" then
        local ok, triangles = pcall(love.math.triangulate, L5_env.vertices)
        if ok then
          local meshVerts = {}
          for _, tri in ipairs(triangles) do
            for i = 1, 6, 2 do
              meshVerts[#meshVerts+1] = {tri[i], tri[i+1]}
            end
          end
          L5_env.mesh:setVertices(meshVerts, 1, #meshVerts)
          L5_env.mesh:setDrawMode("triangles")
          L5_env.mesh:setDrawRange(1, #meshVerts)
          love.graphics.draw(L5_env.mesh)
        else
          love.graphics.polygon("fill", L5_env.vertices)
        end
      end
      local r, g, b, a = love.graphics.getColor()
      love.graphics.setColor(unpack(L5_env.stroke_color))
      if _close == CLOSE then
        local verts = L5_env.vertices
        -- draw all segments
        love.graphics.line(verts[1], verts[2], unpack(verts, 3, #verts))
        -- close by drawing back to start
        love.graphics.line(verts[#verts-1], verts[#verts], verts[1], verts[2])
      else
        -- continuous lines, doesn't close the last two segments aka OPEN
        love.graphics.line(L5_env.vertices)
      end
      love.graphics.setColor(r, g, b, a)
    end
  end
end

---Draws a Bézier curve, defined by two anchor points and two control points
---The first 2 parameters set an x1, y1 anchor point.
---The next 4 parameters set two paired x2, y2, x3, y3 control points that 'pull' the curve toward them
---The last 2 parameters x4, y4 set the last anchor point where the curve ends
---@type fun(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, x4: number, y4: number)
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

---Draws a curve using Catmull-Rom spline.
---Spline curves can form shapes and curves that slope gently.
---The first 2 parameters x1, y1 set the first control point (not drawn).
---The next 4 parameters x2, y2, x3, y3 set the starting and ending point of the visible segment.
---The last 2 parameters x4, y4 set the last control point (not drawn).
---@type fun(x1: number, y1: number, x2: number, y2: number, x3: number, y3: number, x4: number, y4: number)
---@see bezier
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

---Calculates the fractional part of a number.
---@param _n number 
---@return number fraction Returns the number's decimal fractional part, matching the sign of the input.
function fract(_n)
  return _n - int(_n)
end

---Calculates the natural logarithm (the base-e logarithm) of a number.
---@param _n number Must be greater than 0 due to definition of natural log.
---@return number log Returns the number's natural log.
function log(_n)
  if _n > 0 then
    return math.log(_n)
  else
    error("log() expects input greater than 0.")
  end
end

---Calculates exponential expressions.
---For example, `pow(2, 3)` evaluates the expression 2 x 2 x 2
---@param n number Sets the base of the exponent.
---@param e number Sets the power by which to raise the base.
---@return number value 
function pow(n, e)
  return n ^ e
end

---Calculates the value of Euler's number e (2.71828...) raised to the power of a number.
---@param n number Exponent to raise.
---@return number value
function exp(n)
  return math.exp(n)
end

---Maps a number from input range to a value between 0 and 1.
---Numbers outside of the original range are not constrained between 0 and 1. Out-of-range values are often intentional and useful.
---@param val number Incoming value to be normalized.
---@param start number Lower bound of the value's current range.
---@param stop number Upper bound of the value's current range.
---@return number normalized The normalized value output.
function norm(val, start, stop)
  -- normalize the value to 0-1 range
  return (val - start) / (stop - start)
end

---Calculates a number between two numbers at a specific increment.
---If the value of amt is less than 0 or more than 1, lerp() will return a number outside of the original interval.
---@param start number First value.
---@param stop number Second value.
---@param amt number Amount to interpolate between the two numbers. 0.1 is near 1st number. 0.5 is halfway between.
---@return number lerped The lerped value.
function lerp(start, stop, amt)
  return start + (stop - start) * amt
end

---Calculates the square of a number.
---@param n number Number to square.
---@return number Squared number.
function sq(n)
  return n * n
end

---Calculates the square root of a number.
---@param n number Number to square root.
---@return number sqrt Square root of number.
function sqrt(n)
  if n >= 0 then
    return math.sqrt(n)
  else
    error("sqrt() requires non-negative number input.")
  end
end

---Returns a random number or a random element from an array.
---random() follows uniform distribution, which means that all outcomes are equally likely. 
---By default random() produces different results each time.
---@overload fun(): number Returns a random number 0 to 1
---@overload fun(_a: number): number Returns a random number between 0 and that number
---@overload fun(_a: number, _b: number): number With 2 parameters returns a random number in given range, exclusive of the upper limit
---@overload fun(_a: table): any Selects a random selection from the passed table
---@see noise
---@see randomGaussian
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

---Sets the seed value for the random() and randomGaussian() functions.
---Calling randomSeed() with a constant argument allows random() and randomGaussian() to produce the same results each time
---@param seed number
---@see randomGaussian
function randomSeed(seed)
  love.math.setRandomSeed(seed)
end

---Returns random numbers that can be tuned to feel organic. Always returns numbers normalized 0 to 1.
---Calls to noise() with similar inputs will produce similar outputs. 
---Uses simplex noise for 1 and 2 arguments and Perlin noise algorithm for 3 arguments.
---@param ... number
---@return number
---@overload fun(_x: number): number Computes noise values in one dimension, such as space `noise(x)` or time, `noise(t)`.
---@overload fun(_x: number, _y: number): number Computes noise values in two dimensions, such as space `noise(x, y)` or space and time, `noise(x, t)`.
---@overload fun(_x: number, _y: number, _z: number): number Computes noise values in three dimensions, such as space `noise(x, y, z)` or space and time, `noise(x, y, t)`.
---@see random
function noise(...)
  return love.math.noise(...)
end

---Returns a random number fitting a Gaussian, or normal, distribution.
---@overload fun(): number Returns values with a mean of 0 and standard deviation of 1
---@overload fun(mean: number): number Takes an argument as the mean. Returns values with a standard deviation of 1.
---@overload fun(mean: number, sd: number): number Takes an argument as the mean. Returns values with second argument as the standard deviation.
---@see random
---@see randomSeed
randomGaussian = (function()
--self-contained, optional params
--Box-Muller transform
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

---Calculates the absolute value of a number, its distance from zero on the number line.
---@param _a number
---@return number abs
function abs(_a)
  return math.abs(_a)
end

---Calculates the integer closest to a number.
---@param n number
---@param decimals? number Optional parameter to set number of decimal places. Default is 0.
---@return number rounded
function round(n, decimals)
  decimals = decimals or 0
  local mult = 10 ^ decimals
  return math.floor(n * mult + 0.5) / mult
end

---Converts a boolean, string, decimal to an integer by stripping the decimal. Also converts a table of values to a table of integers.
---@param _a number|string|boolean|table
---@return number|table|nil result The truncated integer or table of truncated values, or nil if invalid.
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
    
    -- strip decimal via floor (or ceil if a neg number)
    if num >= 0 then
      return math.floor(num)
    else
      return math.ceil(num) + 0 --adding 0 normalizes -0.0 to 0.0 (a floating-point quirk of ceil() returning negative zero between 0 and -1)
    end
end

---Calculates the closest integer value that is greater than or equal to a number.
---@param _a number
---@return number int
function ceil(_a)
  return math.ceil(_a)
end

---Calculates the closest integer value that is less than or equal to a number.
---@param _a number
---@return number int
function floor(_a)
  return math.floor(_a)
end

---Returns the largest value in a sequence of numbers.
---@overload fun(...: number): number
---@overload fun(numbers: table): number
function max(...)
  local args = {...}
  -- If single table argument, unpack it
  if #args == 1 and type(args[1]) == "table" then
    return math.max(unpack(args[1]))
  else
    return math.max(unpack(args))
  end
end

---Returns the smallest value in a sequence of numbers.
---@overload fun(...: number): number
---@overload fun(numbers: table): number
function min(...)
  local args = {...}
  -- If single table argument, unpack it
  if #args == 1 and type(args[1]) == "table" then
    return math.min(unpack(args[1]))
  else
    return math.min(unpack(args))
  end
end

---Constrains a number between a minimum and maximum value.
---@param _val number Value to constrain.
---@param _min number Minimum limit.
---@param _max number Maximum limit.
---@return number constrained Constrained number
function constrain(_val,_min,_max)
  return math.max(_min, math.min(_val,_max));
end


---Re-maps a number from one range to another.
---@param _val number Value to be remapped.
---@param inputMin number Lower bound of the value's current range.
---@param inputMax number Upper bound of the value's current range.
---@param outputMin number Lower bound of the value's target range.
---@param outputMax number Upper bound of the value's target range.
---@param withinBounds? boolean By default, values outside the target range can be returned. Setting this optionally to true will constrain the value to the newly mapped range.
---@return number mapped Output value.
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

---Calculates the distance between two points.
---@type fun(x1: number, y1: number, x2: number, y2: number): number
function dist(x1,y1,x2,y2)
  return ((x2-x1)^2+(y2-y1)^2)^0.5
end

-------------------- TRIGONOMETRY --------------------

---Changes the unit system used to measure angles.
---Calling angleMode() with no arguments returns current angle mode, which is either RADIANS or DEGREES.
---@param _mode? string Either RADIANS (default) or DEGREES
---@return string? mode The current angle mode, only returned when called without arguments. 
function angleMode(_mode)
  if not _mode then
    return L5_env.degree_mode
  elseif _mode == RADIANS or _mode == DEGREES then
    L5_env.degree_mode = _mode
  else
    error("angleMode() must be RADIANS or DEGREES")
  end
end

---Converts an angle measured in radians to its value in degrees.
---Degrees and radians are both units for measuring angles. There are 360˚ in one full rotation. A full rotation is 2 × π (about 6.28) radians.
---@param _angle number 
---@return number degrees
function degrees(_angle)
  return math.deg(_angle)
end

---Converts an angle measured in degrees to its value in radians.
---Degrees and radians are both units for measuring angles. There are 360˚ in one full rotation. A full rotation is 2 × π (about 6.28) radians.
---@param _angle number 
---@return number radians
function radians(_angle)
  return math.rad(_angle)
end

---Calculates the sine of an angle. 
---The angle is interpreted in radians or degrees depending on the current angleMode() (default: RADIANS)
---@param _angle number
---@return number sine
function sin(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.sin(_angle)
  else
    return math.sin(radians(_angle))
  end
end

---Calculates the arcsine of a number, the inverse of sin().
---By default, asin() returns values in the range -π ÷ 2 (about -1.57) to π ÷ 2 (about 1.57). If the angleMode() is DEGREES then values are returned in the range -90 to 90.
---@param _angle number
---@return number asin
function asin(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.asin(_angle)
  else
    return degrees(math.asin(_angle))
  end
end

---Calculates the cosine of an angle. 
---The angle is interpreted in radians or degrees depending on the current angleMode() (default: RADIANS)
---@param _angle number
---@return number cosine
function cos(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.cos(_angle)
  else
    return math.cos(radians(_angle))
  end
end

---Calculates the arccosine of a number, the inverse of cos().
---By default, acos() returns values in the range 0 to π radians (about 3.14). If the angleMode() is DEGREES then values are returned in the range -90 to 90.
---@param _angle number
---@return number acos
function acos(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.acos(_angle)
  else
    return degrees(math.acos(_angle))
  end
end

---Calculates the tangent of an angle. 
---The angle is interpreted in radians or degrees depending on the current angleMode() (default: RADIANS)
---@param _angle number
---@return number tangent
function tan(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.tan(_angle)
  else
    return math.tan(radians(_angle))
  end
end

---Calculates the arctangent of a number, the inverse of tan().
---By default, atan() returns values in the range -π ÷ 2 (about -1.57) to π ÷ 2 (about 1.57). If the angleMode() is DEGREES then values are returned in the range -90 to 90.
---@param _angle number
---@return number atan
function atan(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.atan(_angle)
  else
    return degrees(math.atan(_angle))
  end
end

---Calculates the angle formed by a point, the origin, and the positive x-axis.
---atan2() is most often used for orienting geometry to the mouse's position, as in atan2(mouseY, mouseX).
---By default, atan2() returns values in the range -π (about -3.14) to π (about 3.14). If the angleMode() is DEGREES then values are returned in the range -180 to 180.
---@param y number
---@param x number
---@return number angle Angle in RADIANS or DEGREES depending on angleMode()
function atan2(y, x)
  local angle = math.atan2(y, x)  -- This returns radians
  
  if L5_env.degree_mode == RADIANS then
    return angle
  else
    return math.deg(angle)
  end
end

---------------------- DATA ------------------------

---Converts a string, number or table to a boolean
---If n is a string, only the exact value "true" returns true — every other string (including "false") returns false.
---If n is a number, 0 returns false and every other value (positive or negative) returns true.
---If n is a table, each element is converted and returned as a table 
---@param n table|string|number|boolean
---@return boolean|table result The converted boolean or a table of converted booleans 
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

---Converts a Boolean, String, or Number to its byte value.
---byte() converts a value to an integer (whole number) between -128 and 127. Values greater than 127 wrap around while negative values are unchanged.
---If n represents a number as a string (e.g. "ten"), it's converted directly. If it's a non-numeric string, the byte value of its first character is used instead.
---If an array is passed, then an array of byte values will be returned.
---@param n table|boolean|string|number
---@return number|table byte_value
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

---Converts a number, string, or boolean to a single-character string.
---If n represents a number as a string (e.g. "65"), it's converted directly. If a non-numeric string, the first character is returned.
---If a table is passed, a table of single character strings is returned
---@param n table|string|number|boolean
---@return string|table char
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
    if int_val >= 0 and int_val <= 127 then -- only ASCII range is safely displayable
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

---Converts a String (and Boolean) to a floating point (decimal) Number.
---float() converts strings that resemble numbers, such as '12.34', into numbers.
---A passed table will convert all values, returning a table of floats.
---Invalid input will return nil.
---@param str number|boolean|string|table 
---@return number|table|nil float
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

---Converts a number to a string with its hexadecimal value.
---Or converts a table of strings with their hexadecimal values.
---@param n number|table Number to convert.
---@param digits? number Number of hexadecimal digits to display.
---@return string|table hexadecimal Converted hexadecimal value.
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
  
  -- check if valid
  local num = tonumber(n)
  if not num then
    error("hex() requires a number or numeric string")
  end

  -- convert to int
  local int_val = math.floor(num)
  
  -- convert to hex string uppercase
  local hex_str = string.format("%X", int_val)
  
  -- pad with zeros if needed
  if #hex_str < digits then
    hex_str = string.rep("0", digits - #hex_str) .. hex_str
  end
  
  return hex_str
end

---Converts a boolean or number to string.
---If passed a table, will return a table of strings. Strings will be returned unchanged.
---@param n number|boolean|string|table
---@return string|table strings
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

---Converts a single-character string, or first character in longer string to a Number.
---If passed a table, returns a table of uncharred numbers.
---Numbers are passed through.
---@param n string|table|number
---@return number|table|nil uncharred
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

---Converts a String with a hexadecimal value to a Number. Invalid hex strings return nil.
---If passed a table, returns a table of numbers. unhexed numbers are passed through.
---@param n string|table|number
---@return number|table|nil unhexed
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

---Loads a font and creates a font object. 
---Fonts can be Truetype (.ttf), OpenType fonts (.otf), or Bitmap Fonts.
---@param fontPath string
---@return Font font
function loadFont(fontPath)
  local font = love.graphics.newFont(fontPath)
  -- Store the path so we can recreate the font at different sizes
  L5_env.fontPaths[font] = fontPath
  return font
end

---Sets the font used by the text() function.
---@param font Font A font loaded previously with loadFont().
---@param size? number Optional. Sets font size in pixels. Same effect as calling textSize().
---@see loadFont
---@see textSize
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

---Sets the font size when text() is called, or gets the font size if no arguments.
---@param size? number Size in pixels.
---@return number? size
function textSize(size)
  if not size then
    return L5_env.currentFontSize
  end
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

---Calculates the maximum width of a string of text drawn when text() is called.
---@param _text string
---@return number size
function textWidth(_text)
  local font = L5_env.currentFont or love.graphics.getFont()
  return font:getWidth(_text)
end

---Calculates the maximum height of a string of text drawn when text() is called.
---Note: textHeight() includes the spacing between lines (called "leading") which may differ from a letter's height. Using textAscent() + textDescent() may more closely calculate letter height without spacing.
---@return number size
function textHeight()
  local font = L5_env.currentFont or love.graphics.getFont()
  return font:getHeight()
end

---Returns the ascent, the distance from the baseline to the highest point of the current font when drawn with text().
---@return number size
function textAscent()
  local font = L5_env.currentFont or love.graphics.getFont()
  return font:getAscent()
end

---Returns the descent, the distance from the baseline to the lowest point of the current font when drawn with text().
---@return number size
function textDescent()
  local font = L5_env.currentFont or love.graphics.getFont()
  return math.abs(font:getDescent())
end

--------------------- SYSTEM -----------------------

---Quits/stops/exits the program and closes the program window.
function exit()
  love.event.quit()
end

---Adds a text label to the window's title bar.
---Calling windowTitle without an argument returns the current window title, or "Untitled" if it hasn't been set.
---@param _title? string
---@return string? title
function windowTitle(_title)
  if _title ~= nil then
    love.window.setTitle(_title)
  else 
    return love.window.getTitle()
  end
end

---Resizes the window to a given width and height.
---Clears the drawing surface and calls windowResized() if defined
---@param _w number
---@param _h number
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

---Clears the screen to transparent black.
function clear()
  love.graphics.clear()
end

---Returns the display's current pixel density.
---@return number pixelDensity
function displayDensity()
  return love.graphics.getDPIScale()
end

---Sets or gets the number of frames drawn per second.
---@param _inp? number Optional: sets the frameRate in frames per second
---@return number rate Returned if no arguments given.
function frameRate(_inp)
  if _inp then --change frameRate
    L5_env.framerate = _inp 
  else --get frameRate
    return love.timer.getFPS( )
  end
end

---Stops the code in draw() from running repeatedly.
---The draw loop can be restarted by calling loop(). draw() can be run once by calling redraw().
---isLooping() can be useful to check whether a sketch is looping
---@see loop
---@see redraw
---@see isLooping
function noLoop()
  L5_env.drawing = false 
end

---Resumes the draw loop after noLoop() has been called.
---@see noLoop
function loop()
  L5_env.drawing = true 
end

---Useful to check whether a sketch is looping, such as in `isLooping() == true`.
---@return boolean looping
---@see noLoop
---@see loop
function isLooping()
  if L5_env.drawing then 
    return true
  else
    return false
  end
end

---Runs the code in draw() once.
---@see noLoop
---@see loop
function redraw()
  draw()
  noLoop()
end

--------------------- TYPOGRAPHY ---------------------

---Draws text to the canvas.
---Color is set by fill().
---By default, the x-coordinate sets the edge of text, and the y-coordinate sets its baseline. Can be changed with textAlign().
---@param _msg string The text to be drawn.
---@param _x number X-coordinate of the text. 
---@param _y number Y-coordinate of the text.
---@param _w? number Sets the width of the invisible rectangle containing the text, wrapping to a new line if text is longer.
---@see textAlign
---@see textWrap
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
      
      local buffer = {}
      for i = 1, #_msg do
	local char = _msg:sub(i, i)
	local charWidth = font:getWidth(char)
	if lineWidth + charWidth > _w then
	  table.insert(buffer, "\n")
	  table.insert(buffer, char)
	  lineWidth = charWidth
	else
	  table.insert(buffer, char)
	  lineWidth = lineWidth + charWidth
	end
      end
      wrappedText = table.concat(buffer)
      
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

---Sets the way text is aligned when text() is called.
---Changes the way text() interprets x and y arguments in the text() function.
---Default for text() without textAlign() is LEFT, BASELINE. 
---Omitting y_alignment resets vertical alignment to BASELINE
---@param x_alignment string LEFT, CENTER, or RIGHT alignment for x-coordinate of text().
---@param y_alignment? string TOP, BOTTOM, CENTER, or BASELINE alignment for y-coordinate of text().
---@see text
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

---Sets the style for wrapping text when text() is called. Default is WORD.
---With no argument, returns current style
---@param _style? string WORD or CHAR
---@return string? currentwrap
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

----------------------- IMAGE ------------------------
---------------- LOADING & DISPLAYING ----------------

---Loads an image from a specified file path. 
---Possible image formats accepted are: .jpg, .jpeg, .png, .bpm, .tga, .hdr, .pic, .exr. Unsupported filetypes include .webp and .gif.
---@param _filename string Path to image file.
---@return Image
function loadImage(_filename)
  local success, result = pcall(love.graphics.newImage, _filename)
  
  if success then
    return result
  else
    error("Failed to load image '" .. _filename .. "': " .. tostring(result))
  end
end

---Loads and returns a video file for simple audio/video playback.
---Videos get drawn to the screen with image().
---L5 can only play ogv (Ogg Theora) video files. Use an external program such as Handbrake or ffmpeg (command line) to convert mp4, avi, mkv, and mov codecs first.
---Video methods :play(), pause(), stop(), loop(), noLoop(), time(), volume()
---Note: Videos with audio may experience sync issues when looping
---@param _filename string
---@return Video video
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

---Draws an image to the canvas
---x, y coordinate are set with imageMode. Default: CORNER.
---Drawn at their full size unless a width and height are specified.
---@param _img Image
---@param _x number x-coordinate to draw image, can be altered with imageMode()
---@param _y number y-coordinate to draw image, can be altered with imageMode()
---@param _w? number width of image (optional), or second corner's x-coordinate in CORNERS mode (required)
---@param _h? number height of image (optional), or second corner's y-coordinate in CORNERS mode (required)
---@see imageMode
function image(_img,_x,_y,_w,_h)
  --check if offscreen buffer, if so, allow passing in the buffer directly
  if type(_img) == "table" and _img._canvas then
    _img = _img._canvas
  end

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

---Masks part of the image with another.
---Uses another image's alpha channel as the alpha channel for this image. 
---Masks are cumulative and can't be removed once applied. If the mask has a different pixel density from this image, the mask will be scaled.
---@param img Image
---@param maskImage Image
function mask(img, maskImage)
  -- save current graphics state
  local prevCanvas = love.graphics.getCanvas()
  local prevBlendMode = love.graphics.getBlendMode()
  
  -- get ImageData by rendering to temporary canvas
  local w = img:getWidth()
  local h = img:getHeight()
  
  -- create temporary canvas for img
  local imgCanvas = love.graphics.newCanvas(w, h)
  love.graphics.setCanvas(imgCanvas)
  love.graphics.clear()
  love.graphics.draw(img, 0, 0)
  love.graphics.setCanvas()
  local imgData = imgCanvas:newImageData()
  imgCanvas:release()
  
  -- create temporary canvas for mask
  local maskW = maskImage:getWidth()
  local maskH = maskImage:getHeight()
  local maskCanvas = love.graphics.newCanvas(maskW, maskH)
  love.graphics.setCanvas(maskCanvas)
  love.graphics.clear()
  love.graphics.draw(maskImage, 0, 0)
  love.graphics.setCanvas()
  local maskData = maskCanvas:newImageData()
  maskCanvas:release()
  
  -- scale mask if needed
  if w ~= maskW or h ~= maskH then
    local scaledMaskData = love.image.newImageData(w, h)
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local mx = floor(x * maskW / w)
        local my = floor(y * maskH / h)
        local mr, mg, mb, ma = maskData:getPixel(mx, my)
        scaledMaskData:setPixel(x, y, mr, mg, mb, ma)
      end
    end
    maskData = scaledMaskData
  end
  
  -- apply mask using mask's alpha channel
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local r, g, b, a = imgData:getPixel(x, y)
      local mr, mg, mb, ma = maskData:getPixel(x, y)
      
      -- multiply alpha (cumulative)
      imgData:setPixel(x, y, r, g, b, a * ma)
    end
  end
  
  -- update the image
  img:replacePixels(imgData)
  
  -- restore graphics state
  love.graphics.setCanvas(prevCanvas)
  love.graphics.setBlendMode(prevBlendMode)
end

---Tints images using a color.
---@overload fun(gray: number)
---@overload fun(hex: string)
---@overload fun(colorName: string)
---@overload fun(gray: number, alpha: number)
---@overload fun(r: number, g: number, b: number) RGB mode (default) or HSB.
---@overload fun(r: number, g: number, b: number, a: number)
---@overload fun(colors: table) A table of {r, g, b} or {r, g, b, a} values
---@see colorMode
function tint(...)
  local args = {...}
  if #args == 1 and type(args[1]) == "table" then
    L5_env.currentTint = toColor(unpack(args[1]))
  else
    L5_env.currentTint = toColor(...)
  end
end

---Removes the current tint set by tint().
---@see tint
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
       (actualDrawable:type() == "Image" or actualDrawable:type() == "Video" or actualDrawable:type() == "Canvas") then
        if L5_env.currentTint then
            love.graphics.setColor(unpack(L5_env.currentTint))
        else
            love.graphics.setColor(1, 1, 1, 1)  -- No tint = white
        end
    end
    
    originalDraw(actualDrawable, x, y, r, sx, sy, ox, oy, kx, ky)
    love.graphics.setColor(prevR, prevG, prevB, prevA)
end

---Changes the cursor's appearance.
---Can be specified with path to image file (e.g. 'assets/cursor.png') or of type: ARROW, IBEAM, WAIT, CROSSHAIR, WAITARROW, SIZENWSE, SIZENESW, SIZEWE, SIZENS, SIZEALL, NO, HAND
---Custom cursor images should generally be at most 32 by 32 pixels large.
---The parameters x and y are optional, used for custom image cursors. Sets the location pointed to within the image. (Default: 0,0 -> top left)
---@param _cursor_icon string|userdata
---@param hotX? number
---@param hotY? number
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
  
  --3 options for cursors: built-in LOVE system cursor, pre-loaded image, or a file path to load as image
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
    local success, cursorImage = pcall(love.image.newImageData, _cursor_icon)
    if not success then
      error("cursor() could not load image at path: ".._cursor_icon)
    end
    local _cursor = love.mouse.newCursor(cursorImage, hotX, hotY)
    love.mouse.setCursor(_cursor)
  else
    error("cursor() requires a system cursor name, file path, or ImageData")
  end
end

---Hides the cursor from view.
function noCursor()
  love.mouse.setVisible(false)
end

---------------------- Pixels ----------------------

---Copies pixels from a source image to a region of the canvas.
---copy() will scale pixels from the source region if it isn't the same size as the destination region.
---@param source? Image The image to copy from. Defaults to the current window if omitted.
---@param sx number Source region's top-left x-coordinate.
---@param sy number Source region's top-left y-coordinate.
---@param sw number Source region's width.
---@param sh number Source region's height.
---@param dx number Destination region's top-left x-coordinate.
---@param dy number Destination region's top-left y-coordinate.
---@param dw number Destination region's width.
---@param dh number Destination region's height.
---@see blend
function copy(source, sx, sy, sw, sh, dx, dy, dw, dh)
    -- If source is nil, try to use the current canvas
    if source == nil then
        source = love.graphics.getCanvas()
        
        -- If still nil, we can't copy from the screen
        if source == nil then
            error("copy() requires a source image or an active canvas")
        end
    end
    
    local quad = love.graphics.newQuad(sx, sy, sw, sh, source:getDimensions())
    
    local scaleX = dw / sw
    local scaleY = dh / sh
    love.graphics.draw(source, quad, dx, dy, 0, scaleX, scaleY)
end

---Copies a region of pixels from one image to another.
---@param source? Image The image to blend. Defaults to the current window if omitted.
---@param sx number Source region's top-left x-coordinate.
---@param sy number Source region's top-left y-coordinate.
---@param sw number Source region's width.
---@param sh number Source region's height.
---@param dx number Destination region's top-left x-coordinate.
---@param dy number Destination region's top-left y-coordinate.
---@param dw number Destination region's width.
---@param dh number Destination region's height.
---@param blendMode string BLEND, NORMAL, ADD, MULTIPLY, SCREEN, LIGHTEST, DARKEST, or REPLACE
---@see copy
function blend(source, sx, sy, sw, sh, dx, dy, dw, dh, blendMode)
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

---Applies an image filter to the canvas.
---@param _name string Filter options are: INVERT, GRAY, THRESHOLD, POSTERIZE, BLUR, ERODE, DILATE.
---@param _param? number Secondary parameter for THRESHOLD (default: 0.5), POSTERIZE (default: 4), BLUR (default: 4). Not used for INVERT, GRAY, ERODE, or DILATE.
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
    if L5_filter.blurSupportsParameter then
        -- Scale to match p5.js: their radius 4 = our radius 15
        local radius = (_param or 4.0) * 5.5
        L5_filter.blur_horizontal:send("blurRadius", radius)
        L5_filter.blur_vertical:send("blurRadius", radius)
        L5_env.filterOn = true
        L5_env.filter = "blur_twopass"
    elseif L5_filter.blur then
        L5_env.filterOn = true
        L5_env.filter = L5_filter.blur
    else
        print("Blur filter not available on this system")
    end
  elseif _name == ERODE then
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.erode
  elseif _name == DILATE then
    L5_env.filterOn = true 
    L5_env.filter = L5_filter.dilate
  else
    error("Error: not a filter name.")
  end
end

---Loads the current value of each pixel on the canvas into the pixels array.
---@see updatePixels
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

---Updates the canvas with the RGBA values in the pixels array.
---updatePixels() only needs to be called after changing values in the pixels array directly, following a call to loadPixels().
---@see loadPixels
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

---Gets a pixel or a region of pixels from the canvas.
---get() is easy to use but it's not as fast as pixels. Use pixels to read many pixel values.
---With no parameters, get returns the entire window.
---@overload fun():Image Returns the entire window.
---@overload fun(x: number, y: number):table Returns the {R, G, B, A} values of the pixel at the given point as a table.
---@overload fun(x: number, y: number, w: number, h: number):Image Returns a subsection of the canvas as an image. The first two parameters are the coordinates for the upper-left corner of the subsection. The last two parameters are the width and height of the subsection.
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
        return {r * 255, g * 255, b * 255, a * 255}
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

---Sets the color of a pixel or draws an image to the canvas.
---set() is easy to use but it's not as fast as pixels if drawing many pixels individually. Use pixels table array to batch set many pixel values instead of once per at a time.
---Changes drawn with set() are immediate. 
---@param x number X-coordinate 
---@param y number Y-coordinate
---@param c number|table|Image Interprets the last parameter as a grayscale value, a {R, G, B, A} pixel array, or an image object. 
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
local function createShaderSafe(shaderCode, fallbackMessage)
  local success, shader = pcall(love.graphics.newShader, shaderCode)
  if success then
    return shader
  else
    print("Warning: " .. fallbackMessage)
    return nil
  end
end

L5_filter.grayscale = createShaderSafe([[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) 
    {
        vec4 pixel = Texel(texture, texture_coords);
        float gray = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));
        return vec4(gray, gray, gray, pixel.a) * color;
    }
]], "Grayscale shader failed to compile - filter unavailable")

--from https://www.love2d.org/forums/viewtopic.php?t=3733&start=300, modified to work on Mac
L5_filter.threshold = createShaderSafe([[
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
]], "Threshold shader failed to compile - filter unavailable")

-- from https://www.reddit.com/r/love2d/comments/ee8n0j/how_to_make_inverted_colornegative_shader/fcaouw5/
L5_filter.invert = createShaderSafe([[ 
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords) 
  { 
	vec4 col = Texel( texture, texture_coords ); 
	return vec4(1.0-col.r, 1.0-col.g, 1.0-col.b, col.a) * color; 
  } 
]], "Invert shader failed to compile - filter unavailable")

L5_filter.posterize = createShaderSafe([[
    uniform float levels;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec4 pixel = Texel(texture, texture_coords);
        
        pixel.r = floor(pixel.r * levels) / levels;
        pixel.g = floor(pixel.g * levels) / levels;
        pixel.b = floor(pixel.b * levels) / levels;
        
        return pixel * color;
    }
]], "Posterize shader failed to compile - filter unavailable")

-- Two-pass blur matching p5.js 2D implementation
L5_filter.blur_horizontal = createShaderSafe([[
    uniform float blurRadius;
    uniform vec2 textureSize;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 pixelSize = 1.0 / textureSize;
        
        // Clamp to minimum radius to avoid divide by zero
        float safeRadius = max(blurRadius, 0.01);

        vec4 sum = vec4(0.0);
        float totalWeight = 0.0;
        
        const int maxSamples = 32;        
        
        // Horizontal pass only
        for(int x = -maxSamples; x <= maxSamples; x++) {
            float fx = float(x);
            float distance = abs(fx);
            
	    if (distance > safeRadius) continue;            

            float radiusi = safeRadius - distance;
            float weight = radiusi * radiusi;
            
            vec2 offset = vec2(fx, 0.0) * pixelSize;
            sum += Texel(texture, texture_coords + offset) * weight;
            totalWeight += weight;
        }
        
        return (sum / totalWeight) * color;
    }
]], "Horizontal blur pass failed to compile")

L5_filter.blur_vertical = createShaderSafe([[
    uniform float blurRadius;
    uniform vec2 textureSize;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 pixelSize = 1.0 / textureSize;

	// Clamp to minimum radius to avoid divide by zero
        float safeRadius = max(blurRadius, 0.01);
        
        vec4 sum = vec4(0.0);
        float totalWeight = 0.0;
        
        const int maxSamples = 32;        

        // Vertical pass only
        for(int y = -maxSamples; y <= maxSamples; y++) {
            float fy = float(y);
            float distance = abs(fy);
            
            if (distance > safeRadius) continue;            
            float radiusi = safeRadius - distance;
            float weight = radiusi * radiusi;
            
            vec2 offset = vec2(0.0, fy) * pixelSize;
            sum += Texel(texture, texture_coords + offset) * weight;
            totalWeight += weight;
        }
        
        return (sum / totalWeight) * color;
    }
]], "Vertical blur pass failed to compile")

-- Track if two-pass blur is available
L5_filter.blurSupportsParameter = (L5_filter.blur_horizontal ~= nil and L5_filter.blur_vertical ~= nil)

-- If two-pass failed, create simple 3x3 Gaussian fallback
if not L5_filter.blurSupportsParameter then
    L5_filter.blur = createShaderSafe([[
        uniform vec2 textureSize;
        
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec2 pixelSize = 1.0 / textureSize;
            vec4 sum = vec4(0.0);
            
            // 3x3 Gaussian kernel (radius 1)
            sum += Texel(texture, texture_coords + vec2(-1.0, -1.0) * pixelSize) * 1.0;
            sum += Texel(texture, texture_coords + vec2( 0.0, -1.0) * pixelSize) * 2.0;
            sum += Texel(texture, texture_coords + vec2( 1.0, -1.0) * pixelSize) * 1.0;
            sum += Texel(texture, texture_coords + vec2(-1.0,  0.0) * pixelSize) * 2.0;
            sum += Texel(texture, texture_coords + vec2( 0.0,  0.0) * pixelSize) * 4.0;
            sum += Texel(texture, texture_coords + vec2( 1.0,  0.0) * pixelSize) * 2.0;
            sum += Texel(texture, texture_coords + vec2(-1.0,  1.0) * pixelSize) * 1.0;
            sum += Texel(texture, texture_coords + vec2( 0.0,  1.0) * pixelSize) * 2.0;
            sum += Texel(texture, texture_coords + vec2( 1.0,  1.0) * pixelSize) * 1.0;
            
            return (sum / 16.0) * color;
        }
    ]], "Blur shader completely unavailable")
end

L5_filter.erode = createShaderSafe([[
    uniform float strength;
    uniform vec2 textureSize;
    
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
        vec2 pixelSize = 1.0 / textureSize;
        
        vec4 centerColor = Texel(texture, texture_coords);
        vec4 result = centerColor;
        
        // 3x3 erosion - unrolled for compatibility
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
]], "Erode shader failed to compile - filter unavailable")

L5_filter.dilate = createShaderSafe([[
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
            // Simplified 3x3 dilation
            vec2 offset;
            vec4 neighborColor;
            float neighborBrightness;
            float weight;
            
            // Unroll 3x3 kernel (excluding center)
            offset = vec2(-1.0, -1.0) * pixelSize;
            neighborColor = Texel(texture, texture_coords + offset);
            neighborBrightness = dot(neighborColor.rgb, vec3(0.299, 0.587, 0.114));
            if (neighborBrightness > threshold) {
                weight = 1.0 - 1.414 / (strength + 1.0);
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
]], "Dilate shader failed to compile - filter unavailable")
