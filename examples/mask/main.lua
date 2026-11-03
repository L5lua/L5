require 'L5'

local photo
local maskImage

function setup()
  size(100,100)
  windowTitle('mask example')

  -- Load the images
  photo = loadImage('assets/rockies.jpg')
  maskImage = loadImage('assets/mask2.png')
  
  -- Apply the mask
  mask(photo, maskImage)
  
  -- Display the image
  image(photo, 0, 0, width, height)
  
  describe('An image of a mountain landscape. The right side of the image has a faded patch of white.')
end
