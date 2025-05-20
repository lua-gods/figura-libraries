---@class HttpRequestBuilder
local httpRequestBuilder = figuraMetatables.HttpRequestBuilder.__index

---@alias auria.http.requestData
---| {future: Future.HttpResponse?, stream: InputStream, code: number, stack: table, streamFuture: Future.String, finish: boolean, callback: function, reader: auria.http.reader}
---@type auria.http.requestData[]
local requests = {}

---sends http request and calls callback at the end
---@param callback fun(result: string, status: number)
---@param reader auria.http.reader?
function httpRequestBuilder:sendAsync(callback, reader)
   if not net:isNetworkingAllowed() then
      callback('networkingNotAllowed', -1)
      return
   end
   do
      local success, result = pcall(net.isLinkAllowed, net, self:getUri())
      if not success or not result then
         callback('linkNotAllowed', -2)
         return
      end
   end
   local success, future = pcall(self.send, self)
   if not success then
      callback(
         future --[[@as string]],
         -3
      )
      return
   end
   table.insert(requests, {
      future = future,
      code = 0,
      stack = {},
      finish = false,
      callback = callback,
      reader = reader or 'string'
   })
end

---@enum (key) auria.http.reader
local readers = {
   string = {
      ---@overload fun(stack: table, value: string, buffer: Buffer?)
      add = function(stack, value, buffer)
         if buffer then
            table.insert(stack, buffer:readByteArray())
         else
            table.insert(stack, value)
         end
      end,
      ---@overload fun(stack: table)
      read = function(stack)
         return table.concat(stack)
      end
   },
   base64 = {
      ---@overload fun(stack: table)
      init = function(stack)
         stack.extra = ''
      end,
      ---@overload fun(stack: table, buffer: Buffer)
      preAdd = function(stack, buffer)
         buffer:writeByteArray(stack.extra)
      end,
      ---@overload fun(stack: table, value: string, buffer: Buffer?)
      add = function(stack, value, buffer)
         local base64 = ''
         local len = 0
         if buffer then
            len = buffer:getLength()
            base64 = buffer:readBase64()
         else
            value = stack.extra .. value
            len = #value
            local buf = data:createBuffer()
            buf:writeByteArray(value)
            buf:setPosition(0)
            base64 = buf:readBase64()
            buf:close()
         end
         local slice = math.floor(len / 12)
         table.insert(stack, base64:sub(1, slice * 16))
         if buffer then
            buffer:setPosition(slice * 12)
            stack.extra = buffer:readByteArray()
         else
            stack.extra = value:sub(slice * 12 + 1, -1)
         end
      end,
      ---@overload fun(stack: table)
      read = function(stack)
         local buffer = data:createBuffer()
         buffer:writeByteArray(stack.extra)
         buffer:setPosition(0)
         table.insert(stack, buffer:readBase64())
         buffer:close()
         return table.concat(stack)
      end
   }
}

---@param v auria.http.requestData
local function processRequest(v)
   local stream = v.stream
   local reader = readers[v.reader]
   if v.streamFuture then
      local future = v.streamFuture
      if not future:isDone() then
         return
      end
      v.streamFuture = nil
      local value = future:getValue()
      reader.add(v.stack, value)
      if #value < 128 then
         v.finish = true
      end
      return
   end
   local available = stream:available()
   if available == 0 then
      ---@diagnostic disable-next-line: redundant-parameter
      v.streamFuture = stream:readAsync(128)
   else
      local byte = stream:read()
      if byte < 0 then
         v.finish = true
         return
      end
      reader.add(v.stack, string.char(byte))
      available = available - 1
      if available > 0 then
         local buffer = data:createBuffer()
         if reader.preAdd then
            reader.preAdd(v.stack, buffer)
         end
         buffer:readFromStream(stream, available)
         buffer:setPosition(0)
         reader.add(v.stack, nil, buffer)
         buffer:close()
      end
   end
end

function events.tick()
   for i, v in pairs(requests) do
      local reader = readers[v.reader]
      if v.future then
         local isDone = v.future:isDone()
         if isDone then
            local res = v.future:getValue()
            v.code = res:getResponseCode()
            v.stream = res:getData()
            v.future = nil
            if reader.init then
               reader.init(v.stack)
            end
         end
      else
         for _ = 1, 8 do
            processRequest(v)
            if v.finish then
               v.stream:close()
               requests[i] = nil
               v.callback(
                  reader.read(v.stack),
                  v.code
               )
               return
            end
         end
      end
   end
end