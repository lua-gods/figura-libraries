-- all these bitwise functions need to be bit32
local bitShiftLeft = bit32.lshift
local bitShiftRight = bit32.rshift
local bitRotLeft = bit32.lrotate
local bitAnd = bit32.band
local bitOr = bit32.bor
local bitXor = bit32.bxor
local bitNot = bit32.bnot

---@param str string
---@return number
local function strToBit32(str)
   return bitShiftLeft(str:byte(1), 24) + bitShiftLeft(str:byte(2), 16) +
      bitShiftLeft(str:byte(3), 8) + str:byte(4)
end

---@param n number
---@return string
local function bit32ToStr(n)
   return string.char(bitAnd(bitShiftRight(n, 24), 0xff), bitAnd(bitShiftRight(n, 16), 0xff),
      bitAnd(bitShiftRight(n, 8), 0xff), bitAnd(n, 0xff))
end

local function sha1(str)
   local h0 = 0x67452301
   local h1 = 0xEFCDAB89
   local h2 = 0x98BADCFE
   local h3 = 0x10325476
   local h4 = 0xC3D2E1F0

   local ml = #str * 8
   local padding = string.char(0x80) .. ('\0'):rep((55 - #str) % 64)
   local lengthStr = string.char(0, 0, 0, 0)..bit32ToStr(ml)

   local msg = str .. padding .. lengthStr

   for chunkI = 1, #msg, 64 do
      local w = {}
      for i = 0, 15 do
         local wordStart = chunkI + i * 4
         w[i] = strToBit32(msg:sub(wordStart, wordStart + 3))
      end
      for i = 16, 79 do
         w[i] = bitRotLeft(bitXor(bitXor(w[i-3], w[i-8]), bitXor(w[i-14], w[i-16])), 1)
      end
      local a = h0
      local b = h1
      local c = h2
      local d = h3
      local e = h4

      local f, k
      for i = 0, 79 do
         if i <= 19 then
            f = bitOr(bitAnd(b, c), bitAnd(bitNot(b), d))
            k = 0x5A827999
         elseif i <= 39 then
            f = bitXor(bitXor(b, c), d)
            k = 0x6ED9EBA1
         elseif i <= 59 then
            f = bitOr(bitOr(bitAnd(b, c), bitAnd(b, d)), bitAnd(c, d))
            k = 0x8F1BBCDC
         else
            f = bitXor(bitXor(b, c), d)
            k = 0xCA62C1D6
         end

         local temp = bitRotLeft(a, 5) + f + e + k + w[i]
         e = d
         d = c
         c = bitRotLeft(b, 30)
         b = a
         a = temp
      end

      h0 = h0 + a
      h1 = h1 + b 
      h2 = h2 + c
      h3 = h3 + d
      h4 = h4 + e
   end

   return (bit32ToStr(h0)..bit32ToStr(h1)..bit32ToStr(h2)..bit32ToStr(h3)..bit32ToStr(h4)):gsub('.', function(a)
	      return string.format('%02X', a:byte())
   end):lower()
end

return sha1
