local historyLen = 10
---@type {[1]: table, [2]: table, [3]: string, [4]: string}[]
local history = {}

---@type fun(depth: number): string
local errorFunc = function(depth) error("", depth) end

---@type {[string]: fun(any): boolean?}
local nanChecks = {
   ['number'] = function(t) return t ~= t end,
   ['Vector2'] = function(v)
      return v.x ~= v.x or v.y ~= v.y
   end,
   ['Vector3'] = function(v)
      return v.x ~= v.x or v.y ~= v.y or v.z ~= v.z
   end,
   ['Vector4'] = function(v)
      return v.x ~= v.x or v.y ~= v.y or v.z ~= v.z or v.w ~= v.w
   end,
   ['Matrix2'] = function(m)
      for x = 1, 2 do
         for y = 1, 2 do
            if m['v'..x..y] ~= m['v'..x..y] then
               return
            end
         end
      end
   end,
   ['Matrix3'] = function(m)
      for x = 1, 3 do
         for y = 1, 3 do
            if m['v'..x..y] ~= m['v'..x..y] then
               return
            end
         end
      end
   end,
   ['Matrix4'] = function(m)
      for x = 1, 4 do
         for y = 1, 4 do
            if m['v'..x..y] ~= m['v'..x..y] then
               return
            end
         end
      end
   end
}

local typeColors = {
   string = 'white',
   number = 'aqua',
   table = '#5da2fb',
   boolean = '#9f54d6',
   ["nil"] = 'red',
   ["function"] = "green",
}

---@param tbl any[]
---@return number?
local function testNans(tbl)
   for i, v in ipairs(tbl) do
      local valueType = type(v)
      if nanChecks[valueType] and nanChecks[valueType](v) then
         return i
      end
   end
end

---@param depth number
---@return string
local function getLine(depth)
   local _, err = pcall(errorFunc, depth)
   return (err:match('^[^\n]+') or '?'):gsub('%s+$', '')
end

---@param tbl any[]
---@return table
local function stringify(tbl)
   local t = {}
   for i, v in ipairs(tbl) do
      t[i] = {tostring(v), type(v)}
   end
   return t
end

---@param value table
---@return table
local function formatType(value)
   local str = value[1]
   if value[2] == 'string' then
      str = '"'..str..'"'
   end
   return {
      text = str,
      color = (typeColors[ value[2] ] or 'yellow')
   }
end

local function printHistory()
   local tbl = {}
   for _, v in ipairs(history) do
      local script, line = v[4]:match('^(.-):(%d+)$')
      if script then
         table.insert(tbl, script)
         table.insert(tbl, {text = ':', color = 'gray'})
         table.insert(tbl, {text = line, color = 'yellow'})
      else
         table.insert(tbl, v[4])
      end
      table.insert(tbl, ' ')
      table.insert(tbl, {text = v[3], color = '#89b4fa'})
      table.insert(tbl, {text = '(', color = '#f38ba8'})
      for i, v2 in ipairs(v[1]) do
         if i ~= 1 then
            table.insert(tbl, {text = ', ', color = 'gray'})
         end
         table.insert(tbl, formatType(v2))
      end
      table.insert(tbl, {text = ')', color = '#f38ba8'})
      table.insert(tbl, {text = ': ', color = 'gray'})
      for i, v2 in ipairs(v[2]) do
         if i ~= 1 then
            table.insert(tbl, {text = ', ', color = 'gray'})
         end
         table.insert(tbl, formatType(v2))
      end
      table.insert(tbl, '\n')
   end
   printJson(toJson(tbl))
end

---@param func function
---@param name string
---@return function
local function wrapFunc(func, name)
   if type(func) ~= "function" then
      return func
   end
   return function(...)
      local input = {...}
      local output = table.pack(func(...))
      -- push to history
      table.insert(history, {stringify(input), stringify(output), name, getLine(5)})
      if #history > historyLen then
         table.remove(history, 1)
      end
      local haveNaN = testNans(input) or testNans(output)
      if haveNaN then
         printHistory()
         error('NaN Found', 2)
      end
      -- return
      return table.unpack(output, 1, output.n)
   end
end

-- patch metatables, if __index is function methods will need to be provided
---@param mt table
---@param prefix string
---@param methods string[]?
local function wrapMetatable(mt, prefix, methods)
   local index = mt.__index
   if type(index) == 'table' then
      for i, v in pairs(index) do
         if type(v) == 'function' then
            index[i] = wrapFunc(v, prefix..i)
         end
      end
   elseif type(index) == 'function' and methods then
      local needsPatching = {}
      for _, v in pairs(methods) do
         needsPatching[v] = true
      end
      local patched = {}
      mt.__index = function(t, i)
         if patched[i] then
            return patched[i]
         end
         local v = index(t, i)
         if needsPatching[i] and type(v) == 'function' then
            needsPatching[i] = nil
            patched[i] = wrapFunc(v, prefix..tostring(i))
            return patched[i]
         end
         return v
      end
   end
end

-- patch stuff
for i, v in pairs(math) do
   math[i] = wrapFunc(v, 'math.'..i)
end

vec = wrapFunc(vec, 'vec')

wrapMetatable(figuraMetatables.VectorsAPI, 'vectors.')
wrapMetatable(figuraMetatables.MatricesAPI, 'matrices.')

wrapMetatable(figuraMetatables.Vector2, 'vec2:', {
	"add", "length", "toString", "floor",
	"ceil", "scale", "offset", "transform",
	"dot", "set", "copy", "normalize",
	"reset", "reduce", "normalized", "sub",
	"mul", "div", "lengthSquared", "unpack",
	"clamped", "toRad", "toDeg", "clampLength",
	"applyFunc", "augmented",
})

wrapMetatable(figuraMetatables.Vector3, 'vec3:', {
	"add", "length", "toString", "floor",
	"ceil", "scale", "offset", "transform",
	"dot", "set", "copy", "normalize",
	"reset", "reduce", "normalized", "sub",
	"mul", "div", "lengthSquared", "cross",
	"unpack", "clamped", "crossed", "toRad",
	"toDeg", "clampLength", "applyFunc", "augmented",
})

wrapMetatable(figuraMetatables.Vector4, 'vec4:', {
	"add", "length", "toString", "floor",
	"ceil", "scale", "offset", "transform",
	"dot", "set", "copy", "normalize",
	"reset", "reduce", "normalized", "sub",
	"mul", "div", "lengthSquared", "unpack",
	"clamped", "toRad", "toDeg", "clampLength",
	"applyFunc",
})

wrapMetatable(figuraMetatables.Matrix2, 'mat2:', {
	"add", "scale", "apply", "set",
	"copy", "reset", "multiply", "rotate",
	"sub", "getColumn", "inverted", "det",
	"transpose", "getRow", "augmented", "invert",
	"transposed", "rightMultiply", "applyDir",
})

wrapMetatable(figuraMetatables.Matrix3, 'mat3:', {
	"add", "scale", "apply", "set",
	"copy", "reset", "multiply", "rotate",
	"sub", "rotateY", "rotateX", "rotateZ",
	"getColumn", "inverted", "det", "transpose",
	"translate", "getRow", "augmented", "invert",
	"transposed", "rightMultiply", "applyDir", "deaugmented",
})

wrapMetatable(figuraMetatables.Matrix4, 'mat4:', {
	"add","scale","apply","set",
	"copy", "reset", "multiply", "rotate",
	"sub", "rotateY", "rotateX", "rotateZ",
	"getColumn", "inverted", "det", "transpose",
	"translate", "getRow", "invert", "transposed",
	"rightMultiply", "applyDir", "deaugmented",
})