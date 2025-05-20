require('http')

local a = net.http:request('https://example.com')

a:sendAsync(function(result, status)
   print(#result, status)
   -- local image = textures:read('test', result)
   -- models:newPart('', 'Hud')
   --    :newSprite('')
   --    :setTexture(image, image:getDimensions():unpack())
end)