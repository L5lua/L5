-- Examples share the same L5.lua file, so tell LÖVE where require() can find it
package.path = package.path .. ";" .. love.filesystem.getSource() .. "/../../?.lua"

require("L5")

local img;

function setup() 
  size(100, 100)

  img = loadImage('/assets/rockies.jpg');
  -- Display the image.
  image(img, 0, 0, 100, 100)

  -- TODO: Revise this when pixelDensity() is implemented
  -- See https://github.com/L5lua/L5/blob/main/docs/TODO.md#pixels
  print("\n=== THIS EXAMPLE IS BROKEN ===")
  print("=== TODO: Check this once pixelDensity() is implemented ===\n")

  -- Get the pixel density.
  local d = pixelDensity()

  -- Calculate the halfway index in the pixels array.
  local halfImage = 4 * (d * width) * (d * height / 2)

  -- Load the pixels array.
  loadPixels()

  -- Copy the top half of the canvas to the bottom.
  for i = 0,halfImage do
    pixels[i + halfImage] = pixels[i]
  end

  -- Update the canvas.
  updatePixels()

  describe('Two identical images of mountain landscapes, one on top of the other.')
end
