-- Custom love.run() function with proper double buffering and mouse events
function love.run()
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
        love.graphics.draw(L5_env.backBuffer, 0, 0)
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

function love.load()
  love.window.setVSync(1)
  love.math.setRandomSeed(os.time())

  -- Create double buffers
  local w, h = love.graphics.getDimensions()
displayWidth, displayHeight = love.window.getDesktopDimensions()
  L5_env.backBuffer = love.graphics.newCanvas(w, h) -- Changed
  L5_env.frontBuffer = love.graphics.newCanvas(w, h) -- Changed

  -- Clear both buffers initially
  love.graphics.setCanvas(L5_env.backBuffer) -- Changed
  love.graphics.clear(0.5, 0.5, 0.5, 1) -- gray background
  love.graphics.setCanvas(L5_env.frontBuffer) -- Changed
  love.graphics.clear(0.5, 0.5, 0.5, 1) -- gray background
  love.graphics.setCanvas()

  defaults()
  if setup ~= nil then setup() end
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

  if isPressed and not L5_env.wasPressed then -- Changed
  -- Mouse was just pressed this frame

  if mousePressed ~= nil then mousePressed() end
    mouseIsPressed = true
  elseif isPressed then -- Still pressed (dragging)
    if mouseDragged ~= nil then mouseDragged() end
    mouseIsPressed = true
  else
    mouseIsPressed = false
  end

  L5_env.wasPressed = isPressed -- Changed

  -- Check for keyboard events in the draw cycle
  if L5_env.keyWasPressed then -- Changed
    if keyPressed ~= nil then keyPressed() end
    L5_env.keyWasPressed = false -- Changed
  end

  if L5_env.keyWasReleased then -- Changed
    if keyReleased ~= nil then keyReleased() end
    L5_env.keyWasReleased = false -- Changed
  end

  if L5_env.keyWasTyped then -- Changed
    if keyTyped ~= nil then keyTyped() end
    L5_env.keyWasTyped = false -- Changed
  end

  -- Check for mouse events in draw cycle
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

function love.keypressed(key, scancode, isrepeat)
  L5_env.keyWasPressed = true -- Changed
end

function love.keyreleased(key)
  L5_env.keyWasReleased = true -- Changed
end

function love.textinput(_text)
  key = _text
  L5_env.keyWasTyped = true -- Changed
end

function love.resize(w, h)
  -- Recreate buffers when window is resized
  if L5_env.backBuffer then L5_env.backBuffer:release() end -- Changed
  if L5_env.frontBuffer then L5_env.frontBuffer:release() end -- Changed

  L5_env.backBuffer = love.graphics.newCanvas(w, h) -- Changed
  L5_env.frontBuffer = love.graphics.newCanvas(w, h) -- Changed

  -- Clear new buffers
  love.graphics.setCanvas(L5_env.backBuffer) -- Changed
  love.graphics.clear(1, 1, 1, 1)
  love.graphics.setCanvas(L5_env.frontBuffer) -- Changed
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
  if L5_env.backBuffer then L5_env.backBuffer:release() end -- Changed
  if L5_env.frontBuffer then L5_env.frontBuffer:release() end -- Changed

  L5_env.backBuffer = love.graphics.newCanvas(_w, _h) -- Changed
  L5_env.frontBuffer = love.graphics.newCanvas(_w, _h) -- Changed

  -- Clear new buffers
  love.graphics.setCanvas(L5_env.backBuffer) -- Changed
  love.graphics.clear(0.5, 0.5, 0.5, 1)
  love.graphics.setCanvas(L5_env.frontBuffer) -- Changed
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
  --if _r is a table return it
  if type(_r) == "table" and _g == nil and #_r == 4 then
    return _r
  end

  --otherwise
  if _g == nil then
    -- one argument = grayscale or color name
    if type(_r) == "number" then
      _r,_g,_b,_a = _r,_r,_r,255
    elseif type(_r) == "string" then
      if _r:sub(1, 1) == "#" then --it's a hex color
    _r, _g, _b = hexToRGB(_r)
    _a = 255
      else --it's a html color value
	--TEST
	if htmlColors[_r] then
	  --END TEST
    _r, _g, _b = table.unpack(htmlColors[_r])
    _a = 255
  else
    error("Color '" .. _r .. "' not found in htmlColors table") 
  end
      end
    else
      --ERROR
      error("Invalid color argument")
    end
  elseif _b == nil then
    -- two arguments = grayscale, alpha
    _a = _g
    _r,_g,_b = _r,_r,_r
  elseif _a == nil then
    -- three arguments = r,g,b
    _a = 255
  end

  return {_r/255, _g/255, _b/255, _a/255}
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
  MITER = "miter"
  BEVEL = "bevel"
  NONE = "none"
  LEFT = "left"
  RIGHT = "right"
  CENTER = "center"
  TOP = "top"
  BOTTOM = "bottom"
  BASELINE = "baseline"
  PI=math.pi
  HALF_PI=math.pi/2
  QUARTER_PI=math.pi/4
  TWO_PI=2*math.pi
  TAU=TWO_PI
  PIE="pie"
  OPEN="open"
  CHORD="closed"

  -- global user vars - can be read by user but shouldn't be altered by user
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
  L5_env.global_degree_mode = RADIANS --also: DEGREES
  L5_env.global_rect_mode = CORNER --also: CORNERS, CENTER
  L5_env.global_ellipse_mode = CENTER
  L5_env.global_image_mode = CORNER
  L5_env.global_fill_mode="fill"   --also: "line"
  L5_env.global_stroke_color = {0,0,0}
  L5_env.currentTint = {1, 1, 1, 1} -- Default: no tint white
  -- global key state
  L5_env.keyWasPressed = false
  L5_env.keyWasReleased = false
  L5_env.keyWasTyped = false
  -- mouse state
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
  if L5_env.global_degree_mode == RADIANS then -- Changed
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

function rect(_a,_b,_c,_d)
  if L5_env.global_rect_mode=="CORNERS" then -- Changed --x1,y1,x2,y2
    love.graphics.rectangle(L5_env.global_fill_mode,_a,_b,_c-_a,_d-_b) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.rectangle("line",_a,_b,_c-_a,_d-_b)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.global_rect_mode=="CENTER" then -- Changed --x-w/2,y-h/2,w,h
    love.graphics.rectangle(L5_env.global_fill_mode, _a-_c/2,_b-_d/2,_c,_d) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c,_d)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.global_rect_mode=="RADIUS" then -- Changed --x-w/2,y-h/2,r1*2,r2*2
    love.graphics.rectangle(L5_env.global_fill_mode, _a-_c/2,_b-_d/2,_c*2,_d*2) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.rectangle("line", _a-_c/2,_b-_d/2,_c*2,_d*2)
    love.graphics.setColor(r, g, b, a)
  else --CORNER default x,y,w,h
    love.graphics.rectangle(L5_env.global_fill_mode,_a,_b,_c,_d) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.rectangle("line",_a,_b,_c,_d)
    love.graphics.setColor(r, g, b, a)
  end
end

function square(_a,_b,_c)
  --CORNERS mode doesn't exist for squares
  if L5_env.global_rect_mode=="CENTER" then -- Changed --x-w/2,y-h/2,w,h
    love.graphics.rectangle(L5_env.global_fill_mode, _a-_c/2,_b-_c/2,_c,_c) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c,_c)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.global_rect_mode=="RADIUS" then -- Changed --x-w/2,y-h/2,r*2,r*2
    love.graphics.rectangle(L5_env.global_fill_mode, _a-_c/2,_b-_c/2,_c*2,_c*2) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.rectangle("line", _a-_c/2,_b-_c/2,_c*2,_c*2)
    love.graphics.setColor(r, g, b, a)
  else --CORNER default x,y,w,h
    love.graphics.rectangle(L5_env.global_fill_mode,_a,_b,_c,_c) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.rectangle("line",_a,_b,_c,_c)
    love.graphics.setColor(r, g, b, a)
  end
end

function ellipse(_a,_b,_c,_d)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  if L5_env.global_ellipse_mode=="RADIUS" then -- Changed
    love.graphics.ellipse(L5_env.global_fill_mode,_a,_b,_c,_d) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.ellipse("line",_a,_b,_c,_d)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.global_ellipse_mode=="CORNER" then -- Changed
    love.graphics.ellipse(L5_env.global_fill_mode,_a+_c/2,_b+_d/2,_c/2,_d/2) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.ellipse("line",_a+_c/2,_b+_d/2,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  elseif L5_env.global_ellipse_mode=="CORNERS" then -- Changed
    love.graphics.ellipse(L5_env.global_fill_mode,_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.ellipse("line",_a+(_c-_a)/2,_b+(_d-_a)/2,(_c-_a)/2,(_d-_b)/2)
    love.graphics.setColor(r, g, b, a)
  else --default CENTER x,y,w/2,h/2
    love.graphics.ellipse(L5_env.global_fill_mode,_a,_b,_c/2,_d/2) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.ellipse("line",_a,_b,_c/2,_d/2)
    love.graphics.setColor(r, g, b, a)
  end
end

function circle(_a,_b,_c)
--love.graphics.ellipse( mode, x, y, radiusx, radiusy, segments )
  love.graphics.ellipse(L5_env.global_fill_mode,_a,_b,_c/2,_c/2) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.ellipse("line",_a,_b,_c/2,_c/2)
    love.graphics.setColor(r, g, b, a)
end

function quad(_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) --this is a 4-sided love2d polygon! a quad implies an applied texture
  --for other # of sides, use processing api call createShape
  love.graphics.polygon(L5_env.global_fill_mode,_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3,_x4,_y4)
    love.graphics.setColor(r, g, b, a)
end

function triangle(_x1,_y1,_x2,_y2,_x3,_y3) --this is a 3-sided love2d polygon
  love.graphics.polygon(L5_env.global_fill_mode,_x1,_y1,_x2,_y2,_x3,_y3) -- Changed
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.polygon("line",_x1,_y1,_x2,_y2,_x3,_y3)
    love.graphics.setColor(r, g, b, a)
end

--p5 calls arctype parameter "mode"
function arc(_x, _y, _w, _h, _start, _stop, _arctype)
  local arctype = _arctype or "pie"
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
    if L5_env.global_fill_mode and L5_env.global_fill_mode ~= "line" then
      love.graphics.ellipse("fill", center_x, center_y, radius_x, radius_y)
    end
    
    if L5_env.global_stroke_color then
      local r, g, b, a = love.graphics.getColor()
      love.graphics.setColor(table.unpack(L5_env.global_stroke_color))
      love.graphics.ellipse("line", center_x, center_y, radius_x, radius_y)
      love.graphics.setColor(r, g, b, a)
    end
  else
    -- Handle elliptical arcs (when _w != _h)
    if math.abs(radius_x - radius_y) < epsilon then
      -- Circular arc - use Love2D's built-in arc function
      local radius = radius_x
      
      if L5_env.global_fill_mode and L5_env.global_fill_mode ~= "line" then
        love.graphics.arc("fill", arctype, center_x, center_y, radius, start_norm, start_norm + arc_span)
      end
      
      if L5_env.global_stroke_color then
        local r, g, b, a = love.graphics.getColor()
        love.graphics.setColor(table.unpack(L5_env.global_stroke_color))
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
  if L5_env.global_fill_mode and L5_env.global_fill_mode ~= "line" and #vertices >= 6 then
    if arctype == "pie" then
      love.graphics.polygon("fill", vertices)
    elseif arctype == "chord" then
      love.graphics.polygon("fill", vertices)
    end
    -- "open" type doesn't get filled
  end
  
  -- Draw stroke
  if L5_env.global_stroke_color then
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color))
    
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
  love.graphics.points(_x,_y)
end

function line(_x1,_y1,_x2,_y2)
  --a line is drawn in the stroke color
    local r, g, b, a = love.graphics.getColor()
    love.graphics.setColor(table.unpack(L5_env.global_stroke_color)) -- Changed
    love.graphics.line(_x1,_y1,_x2,_y2)
    love.graphics.setColor(r, g, b, a)
end

function background(_r,_g,_b,_a)
  love.graphics.clear(table.unpack(toColor(_r,_g,_b,_a)))
  L5_env.clearscreen = true -- Changed
end

--function fill(_r,_g,_b,_a)
function fill(...)
  love.graphics.setColor(table.unpack(toColor(...)))
end

--------------- CREATING and READING ----------------

function color(...)
    local args = {...}
    if #args == 3 then
        return toColor(args[1], args[2], args[3], 255)
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
  return _color[4]*255
end

function red(_color)
  return _color[1]*255
end

function green(_color)
  return _color[2]*255
end

function blue(_color)
  return _color[3]*255
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
  L5_env.global_rect_mode=_mode -- Changed
end

function ellipseMode(_mode)
  L5_env.global_ellipse_mode=_mode -- Changed
end

function imageMode(_mode)
  L5_env.global_image_mode=_mode -- Changed
end

function noFill()
  L5_env.global_fill_mode="line" -- Changed --fill is transparent
end

function strokeWeight(_w)
  love.graphics.setLineWidth(_w)
end

function strokeCap(_style)
  love.graphics.setLineStyle(ROUND)
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
  L5_env.global_stroke_color = toColor(_r,_g,_b,_a) -- Changed
end

function noStroke()
  L5_env.global_stroke_color={0,0,0,0} -- Changed
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
        return L5_env.global_degree_mode -- Changed
    elseif _mode == RADIANS or _mode == DEGREES then
        L5_env.global_degree_mode = _mode -- Changed
    end
end

function degrees(_angle)
  return math.deg(_angle)
end

function radians(_angle)
  return math.rad(_angle)
end

function sin(_angle)
  if L5_env.global_degree_mode == RADIANS then -- Changed
    return math.sin(_angle)
  else
    return math.sin(radians(_angle))
  end
end

function cos(_angle)
  if L5_env.global_degree_mode == RADIANS then -- Changed
    return math.cos(_angle)
  else
    return math.cos(radians(_angle))
  end
end

function tan(_angle)
  if L5_env.global_degree_mode == RADIANS then -- Changed
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

function frameRate(_inp)
  if _inp then --change frameRate
    L5_env.framerate = _inp -- Changed
  else --get frameRate
    return love.timer.getFPS( )
  end
end

function noLoop()
  love.draw = function() end
  L5_env.drawing = false -- Changed
end

function loop()
  love.draw = draw()
  L5_env.drawing = true -- Changed
end

function isLooping()
  if L5_env.drawing then -- Changed
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
  local x_offset
  local y_offset
  
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

  if L5_env.global_image_mode==CENTER then -- Changed
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
        L5_env.currentTint = {1, 1, 1, 1} -- Changed
    elseif g == nil then
        -- One argument = grayscale
        local gray = r / 255
        L5_env.currentTint = {gray, gray, gray, 1} -- Changed
    elseif a == nil then
        L5_env.currentTint = {r/255, g/255, b/255, 1} -- Changed
    else
        -- Four arguments = RGBA (assume 0-255 range)
        L5_env.currentTint = {r/255, g/255, b/255, a/255} -- Changed
    end
end

function noTint()
    L5_env.currentTint = {1, 1, 1, 1} -- Changed
end

-- Override love.graphics.draw to automatically apply tint
local originalDraw = love.graphics.draw
function love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    -- Store current color
    local prevR, prevG, prevB, prevA = love.graphics.getColor()

    -- Apply tint
    love.graphics.setColor(L5_env.currentTint[1], L5_env.currentTint[2], L5_env.currentTint[3], L5_env.currentTint[4]) -- Changed

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
