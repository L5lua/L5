-- Custom love.run() function with proper double buffering and mouse events
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
        local originalSize = size
        size = function() end
        setup()
        size = originalSize
        setupComplete = true
      else
        if love.draw then love.draw() end
      end
      
	-- Handle pending mouse events in drawing context
	if L5_env.pendingMouseClicked then
	  if mouseClicked then
	    mouseClicked(L5_env.pendingMouseClicked.x, L5_env.pendingMouseClicked.y, L5_env.pendingMouseClicked.button)
	  end
	  L5_env.pendingMouseClicked = nil
	end
      
	if L5_env.pendingMouseReleased then
	  if mouseReleased then
	    mouseReleased(L5_env.pendingMouseReleased.x, L5_env.pendingMouseReleased.y, L5_env.pendingMouseReleased.button)
	  end
	  L5_env.pendingMouseReleased = nil
	end
	
	-- Reset to screen and draw the back buffer
	love.graphics.setCanvas()
	if L5_env.backBuffer then

	  if L5_env.filterOn then
	    love.graphics.setShader(L5_env.filter)
	  end

	  love.graphics.draw(L5_env.backBuffer, 0, 0)

	  if L5_env.filterOn then
	    love.graphics.setShader()
	    L5_env.filterOn = false
	  end

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

  -- Create double buffers
  local w, h = love.graphics.getDimensions()
displayWidth, displayHeight = love.window.getDesktopDimensions()
  L5_env.backBuffer = love.graphics.newCanvas(w, h) 
  L5_env.frontBuffer = love.graphics.newCanvas(w, h) 

  -- Clear both buffers initially
  love.graphics.setCanvas(L5_env.backBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1) -- gray background
  love.graphics.setCanvas(L5_env.frontBuffer) 
  love.graphics.clear(0.5, 0.5, 0.5, 1) -- gray background
  love.graphics.setCanvas()

initShaderDefaults()

  if setup ~= nil then setup() end
  fill(255)
end

function love.update(dt)
  mouseX, mouseY = love.mouse.getPosition()
  movedX=mouseX-pmouseX
  movedY=mouseY-pmouseY
  deltaTime = dt
  key = updateLastKeyPressed()

  -- Call user update logic here (more p5.js-like)
  if update ~= nil then update() end
end

function love.draw()
  frameCount = frameCount + 1

  local isPressed = love.mouse.isDown(1) or love.mouse.isDown(2) or love.mouse.isDown(3)

  if isPressed and not L5_env.wasPressed then 
  -- Mouse was just pressed this frame

  if mousePressed ~= nil then mousePressed() end
    mouseIsPressed = true
  elseif isPressed then -- Still pressed (dragging)
    if mouseDragged ~= nil then mouseDragged() end
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
    if keyTyped ~= nil then keyTyped() end
    L5_env.keyWasTyped = false 
  end

  -- Check for mouse events in draw cycle
  if L5_env.mouseWasMoved then
    if mouseMoved ~= nil then mouseMoved() end
    L5_env.mouseWasMoved = false    
  end
  if L5_env.wheelWasMoved then
    if mouseWheel ~= nil then 
      mouseWheel(L5_env.wheelX or 0,L5_env.wheelY or 0) 
    end
    L5_env.wheelWasMoved = false
    L5_env.wheelX = nil
    L5_env.wheelY = nil
  end

-- Reset transformation matrix to identity at start of each frame
  love.graphics.origin()
  love.graphics.push()

  -- Call user draw function
  if draw ~= nil then draw() end

  pmouseX, pmouseY = mouseX,mouseY

  love.graphics.pop()
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

function love.keypressed(key, scancode, isrepeat)
  L5_env.keyWasPressed = true 
end

function love.keyreleased(key)
  L5_env.keyWasReleased = true 
end

function love.textinput(_text)
  key = _text
  L5_env.keyWasTyped = true 
end

function love.resize(w, h)
  -- Recreate buffers when window is resized
  if L5_env.backBuffer then L5_env.backBuffer:release() end 
  if L5_env.frontBuffer then L5_env.frontBuffer:release() end 

  L5_env.backBuffer = love.graphics.newCanvas(w, h) 
  L5_env.frontBuffer = love.graphics.newCanvas(w, h) 

  -- Clear new buffers
  love.graphics.setCanvas(L5_env.backBuffer) 
  love.graphics.clear(1, 1, 1, 1)
  love.graphics.setCanvas(L5_env.frontBuffer) 
  love.graphics.clear(1, 1, 1, 1)
  love.graphics.setCanvas()

  width, height = w, h
end

function love.focus(_focused)
    focused = _focused
end

------------------- CUSTOM FUNCTIONS -----------------

function size(_w, _h)
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
  love.graphics.setCanvas()

  width, height = love.graphics.getDimensions()
end

function fullscreen(_bool)
  --only switch to fullscreen if true and not already fullscreen
  if _bool and not love.window.getFullscreen() then
    love.window.setFullscreen(_bool)
    width, height = love.graphics.getDimensions()
  else
    return love.window.getFullscreen()
  end
end

function environment()
  --background(L5_env.color_max[1],L5_env.color_max[2],L5_env.color_max[3],L5_env.color_max[4])
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
        r, g, b = HSLtoRGB(0, 0, _a / L5_env.color_max[3], 1)
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
      r, g, b = HSLtoRGB(0, 0, _a / L5_env.color_max[3], 1)
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
      r, g, b = HSLtoRGB(_a / L5_env.color_max[1], _b / L5_env.color_max[2], _c / L5_env.color_max[3], 1)
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
      r, g, b = HSLtoRGB(_a / L5_env.color_max[1], _b / L5_env.color_max[2], _c / L5_env.color_max[3], 1)
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

function HSVtoRGB(h, s, v, a) 
    if s <= 0 then 
        return v, v, v, a or L5_env.color_max[4]
    end
    h = h*6
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0, 0, 0
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
    return r+m, g+m, b+m, a or L5_env.color_max[4]
end

function HSLtoRGB(h, s, l, a)
    if s<=0 then 
        return l, l, l, a or L5_env.color_max[4]
    end
    h, s, l = h*6, s, l
    local c = (1-math.abs(2*l-1))*s
    local x = (1-math.abs(h%2-1))*c
    local m,r,g,b = (l-.5*c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end 
    return r+m, g+m, b+m, a or L5_env.color_max[4]
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


function save()
  print("running save")
    love.graphics.captureScreenshot(function(imageData)
        local timestamp = os.date("%Y%m%d_%H%M%S")
        local filename = "screenshot_" .. timestamp .. ".png"
        
        -- Encode to memory (no file yet)
        local pngData = imageData:encode("png")
        
        -- Write directly to current directory
        local programDir = love.filesystem.getSource()
        local targetPath = programDir .. "/" .. filename
        
        local file = io.open(targetPath, "wb")
        if file then
            file:write(pngData:getString())  -- Get the raw data string
            file:close()
            print("Screenshot saved to: " .. targetPath)
        else
            print("Could not write to current directory")
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
  LEFT = "left"
  RIGHT = "right"
  CENTER = "center"
  TOP = "top"
  BOTTOM = "bottom"
  BASELINE = "baseline"
  RGB = "rgb"
  HSB = "hsb"
  HSL = "hsl"
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

  -- global user vars - can be read by user but shouldn't be altered by user
  width = 800 --default, overridden with size() or fullscreen()
  height = 600 --ditto
  frameCount = 0
  mouseIsPressed = false
  mouseX=0
  mouseY=0
  keyIsPressed = false
  key = nil
  pmouseX,pmouseY,movedX,movedY=0,0
  mouseButton = nil
  focused = true
end

-- environment global variables not user-facing
function define_env_globals()
  L5_env = L5_env or {} -- Initialize L5_env if it doesn't exist
  L5_env.drawing = true
  -- drawing mode state
  L5_env.degree_mode = RADIANS --also: DEGREES
  L5_env.rect_mode = CORNER --also: CORNERS, CENTER
  L5_env.ellipse_mode = CENTER
  L5_env.image_mode = CORNER
  -- global color state 
  L5_env.fill_mode="fill"   --also: "line"
  L5_env.stroke_color = {0,0,0}
  L5_env.currentTint = {1, 1, 1, 1} -- Default: no tint white
  L5_env.color_max = {255,255,255,255}
  L5_env.color_mode = RGB --also: HSB, HSL
  -- global key state
  L5_env.keyWasPressed = false
  L5_env.keyWasReleased = false
  L5_env.keyWasTyped = false
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
  -- global font state
  L5_env.fontPaths = {}
  L5_env.currentFontPath = nil
  L5_env.currentFontSize = 12
  L5_env.textAlignX = LEFT
  L5_env.textAlignY = BASELINE
  -- filters (shaders)
  L5_env.filterOn = false
  L5_env.filter = nil
end
------------------ INIT SHADERS ---------------------
-- initialize shader default values
function initShaderDefaults()
    -- Set default values for threshold shader
    L5_filter.threshold:send("soft", 0.3)
    L5_filter.threshold:send("threshold", 0.3)
    
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
  -- Extract file extension
  local extension = _file:match("%.([^%.]+)$")
  
  if extension == "csv" or extension == "tsv" then
    -- Determine separator based on file type
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
    -- Save as CSV or TSV
    local separator = (format == "csv") and "," or "\t"
    local lines = {}
    
    -- Get headers from first row if it's a table with named keys
    local headers = {}
    if #data > 0 and type(data[1]) == "table" then
      for key, _ in pairs(data[1]) do
        if type(key) == "string" then
          table.insert(headers, key)
        end
      end
      
      if #headers > 0 then
        -- Add header row
        table.insert(lines, table.concat(headers, separator))
        
        -- Add data rows using headers
        for i, row in ipairs(data) do
          local values = {}
          for _, header in ipairs(headers) do
            table.insert(values, tostring(row[header] or ""))
          end
          table.insert(lines, table.concat(values, separator))
        end
      else
        -- Array-style table, just use indices
        for i, row in ipairs(data) do
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
      for i, value in ipairs(data) do
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
  local radius_x = _w / 2
  local radius_y = _h / 2
  local center_x = _x
  local center_y = _y
  
  -- Normalize angles to [0, 2π) range
  local function normalize_angle(angle)
    local TWO_PI = 2 * math.pi
    angle = angle % TWO_PI
    if angle < 0 then
      angle = angle + TWO_PI
    end
    return angle
  end
  
  local start_norm = normalize_angle(_start)
  local stop_norm = normalize_angle(_stop)
  
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
  
  if arctype == "pie" then
    -- Add center point for pie
    table.insert(vertices, 1, cy) -- Insert at position 2 (after first vertex)
    table.insert(vertices, 1, cx) -- Insert at position 1
  elseif arctype == "chord" then
    -- Close the arc by connecting endpoints
    -- vertices already has the right points
  end
  -- "open" type doesn't need modification
  
  -- Draw filled arc
  if L5_env.fill_mode and L5_env.fill_mode ~= "line" and #vertices >= 6 then
    if arctype == "pie" then
      love.graphics.polygon("fill", vertices)
    elseif arctype == "chord" then
      love.graphics.polygon("fill", vertices)
    end
    -- "open" type doesn't get filled
  end
  
  -- Draw stroke
  if L5_env.stroke_color then
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(unpack(L5_env.stroke_color))
    
    if arctype == "open" then
      -- Just draw the arc line
      for i = 1, #vertices - 2, 2 do
        love.graphics.line(vertices[i], vertices[i+1], vertices[i+2], vertices[i+3])
      end
    elseif arctype == "chord" then
      -- Draw the arc and the closing line
      love.graphics.polygon("line", vertices)
    elseif arctype == "pie" then
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
  love.graphics.clear(unpack(toColor(_r,_g,_b,_a)))
  L5_env.clearscreen = true 
end

function colorMode(_mode, _max)
  if _mode == RGB or _mode == HSB or _mode == HSL then
    L5_env.color_mode = _mode
  end
  if _max then
    L5_env.color_max = {_max,_max,_max,_max}
  else
    if _mode == RGB then L5_env.color_max = {255,255,255,255} end
    if _mode == HSB or _mode == HSL then L5_env.color_max = {360,100,100,100} end
  end
end

--function fill(_r,_g,_b,_a)
function fill(...)
  L5_env.fill_mode="fill" 
  love.graphics.setColor(unpack(toColor(...)))
end

--------------- CREATING and READING ----------------

function color(...)
    local args = {...}
    if #args == 3 then
        return toColor(args[1], args[2], args[3], L5_env.color_max[4])
    elseif #args == 4 then
        return toColor(args[1], args[2], args[3], args[4])
    elseif #args == 2 then
        return toColor(args[1], args[1], args[1], args[2])  -- This is fine for grayscale+alpha
    elseif #args == 1 then
        return toColor(args[1])  
    else
        error("color() requires 1-4 arguments")
    end
end

function alpha(_color)
  return _color[4]*L5_env.color_max[4]
end

function red(_color)
  return _color[1]*L5_env.color_max[1]
end

function green(_color)
  return _color[2]*L5_env.color_max[2]
end

function blue(_color)
  return _color[3]*L5_env.color_max[3]
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
  L5_env.rect_mode=_mode 
end

function ellipseMode(_mode)
  L5_env.ellipse_mode=_mode 
end

function imageMode(_mode)
  L5_env.image_mode=_mode 
end

function noFill()
  L5_env.fill_mode="line" 
end

function strokeWeight(_w)
  love.graphics.setLineWidth(_w)
  love.graphics.setPointSize(_w) --also sets sizingon points
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
  elseif _a then
    if type(_a) == 'table' then
      -- more robust in case a table isn't ordered by integers
      local keyset = {}
      for k in pairs(_a) do
	  table.insert(keyset, k)
      end
      return _a[keyset[math.random(#keyset)]]
    elseif type(_a) == 'number' then
      return love.math.random()*_a
    end
  else
    return love.math.random()
  end
end

function noise(_x,_y,_z)
  return love.math.noise(_x,_y,_z)
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
  return math.max(unpack(args))
end

function min(...)
  local args={...}
  return math.min(unpack(args))
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

function cos(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.cos(_angle)
  else
    return math.cos(radians(_angle))
  end
end

function tan(_angle)
  if L5_env.degree_mode == RADIANS then 
    return math.tan(_angle)
  else
    return math.tan(radians(_angle))
  end
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
  love.window.setTitle(_title)
end

function resizeWindow(_w,_h)
  love.resize(_w,_h)
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
  love.draw = function() end
  L5_env.drawing = false 
end

function loop()
  love.draw = draw()
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

function text(_msg,_x,_y)
  local x_offset=0
  local y_offset=0
  
  -- set x-offset
  if L5_env.textAlignX==LEFT then
    x_offset = 0
  elseif L5_env.textAlignX == RIGHT then
    x_offset = love.graphics.getFont():getWidth(_msg)
  elseif L5_env.textAlignX == CENTER then
    x_offset = (love.graphics.getFont():getWidth(_msg))/2
  end
  -- set y-offset
  if L5_env.textAlignY == BASELINE then
    y_offset=0
  elseif L5_env.textAlignY == TOP then
    y_offset=0
  elseif L5_env.textAlignY == CENTER then
    y_offset = (love.graphics.getFont():getHeight(_msg))/2
  elseif L5_env.textAlignY == BOTTOM then
    y_offset = love.graphics.getFont():getHeight(_msg)
  end

    love.graphics.print(_msg, _x - x_offset, _y - y_offset)
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

---------------- LOADING & DISPLAYING ----------------

function loadImage(_filename)
  return love.graphics.newImage(_filename)
end

function image(_img,_x,_y,_w,_h)
  local originalWidth = _img:getWidth()
  local originalHeight = _img:getHeight()

  local xscale = _w and (_w/originalWidth) or 1
  local yscale = _h and (_h/originalHeight) or xscale

  if L5_env.image_mode==CENTER then 
    ox=originalWidth/2
    oy=originalHeight/2
  else --TODO: add in CORNERS mode
    ox,oy=0,0
  end

  love.graphics.draw(_img,_x,_y,0,xscale,yscale,ox,oy)
end

function tint(r, g, b, a)
    L5_env.currentTint = toColor(r,g,b,a)
end

function noTint()
    L5_env.currentTint = {1, 1, 1, 1} 
end

-- Override love.graphics.draw to automatically apply tint
local originalDraw = love.graphics.draw
function love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    -- Store current color
    local prevR, prevG, prevB, prevA = love.graphics.getColor()

    -- Apply tint
    love.graphics.setColor(L5_env.currentTint[1], L5_env.currentTint[2], L5_env.currentTint[3], L5_env.currentTint[4]) 

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

---------------------- Pixels ----------------------

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
        
        // 5-tap Gaussian approximation - unrolled for Mac compatibility
        sum += Texel(texture, texture_coords + vec2(0.0, 0.0)) * 0.4;
        sum += Texel(texture, texture_coords + vec2(-blurSize * pixelSize.x, 0.0)) * 0.15;
        sum += Texel(texture, texture_coords + vec2(blurSize * pixelSize.x, 0.0)) * 0.15;
        sum += Texel(texture, texture_coords + vec2(0.0, -blurSize * pixelSize.y)) * 0.15;
        sum += Texel(texture, texture_coords + vec2(0.0, blurSize * pixelSize.y)) * 0.15;
        
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
