BitCluster = {}

function BitCluster:new()
    local o = { bits = {} }
    
    for i = 0, 7 do
        o.bits[i] = 0
    end
    
    setmetatable(o, self)
    self.__index = self
    
    return o
end

function BitCluster:set(i, v)
    self.bits[i] = v
end

function BitCluster:toNumber()
    local n = 0
    
    for i = 0, 7 do
        n = n + (2^i) * self.bits[i]
    end

    return n
end

function BitCluster:toHex()
    return string.format("%02x", self:toNumber())
end

HorizontalBitArray = { }

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function HorizontalBitArray:create(w, h)
    local o = { bytes = {}, width = w, height = h, delta = math.floor(w / 8)}
    setmetatable(o, self)
    self.__index = self
    
    local size = math.floor(w / 8) * h
    
    for i = 0, size - 1 do 
        o.bytes[i] = BitCluster:new()
    end
    
    return o
end

function HorizontalBitArray:set(x, y, color)
    local idx = y * self.delta + math.floor(x / 8)
    local remainder = x % 8

    if color.gray >= 128 then
        self.bytes[idx]:set(7 - remainder, 1)
    end
end

function HorizontalBitArray:toHexArray()
    local data = {}
    
    for i = 0, #self.bytes - 1 do
        data[i] = self.bytes[i]:toHex()
    end
    
    return data
end

VerticalBitArray = { }

function VerticalBitArray:create(w, h)
    local o = { bytes = {}, width = w, height = h, delta = math.floor(h / 8)}
    setmetatable(o, self)
    self.__index = self
    
    local size = math.floor(h / 8) * w
    
    for i = 0, size - 1 do 
        o.bytes[i] = BitCluster:new()
    end
    
    return o
end

function VerticalBitArray:set(x, y, color)
    local idx = x + self.delta * math.floor(y / 8)
    local remainder = y % 8

    if color.gray >= 128 then
        self.bytes[idx]:set(remainder, 1)
    end
end

function VerticalBitArray:toHexArray()
    local data = {}
    
    for i = 0, #self.bytes - 1 do
        data[i] = self.bytes[i]:toHex()
    end
    
    return data
end

HorizontalByteArray = {}
function HorizontalByteArray:create(w, h)
    local o = { bytes = {}, width = w, height = h }
    setmetatable(o, self)
    self.__index = self
    
    local size = w * h
    
    for i = 0, size - 1 do 
        o.bytes[i] = 0
    end
    
    return o
end

function HorizontalByteArray:set(x, y, color)
    local index = y * self.width + x
    self.bytes[index] = color.index
end

function HorizontalByteArray:toHexArray()
    local data = {}
    
    for i = 0, #self.bytes - 1 do
        data[i] = string.format("%02x", self.bytes[i])
    end
    
    return data
end

RGBAByteArray = {}
function RGBAByteArray:create(w, h)
    local o = { bytes = {}, width = w, height = h }
    setmetatable(o, self)
    self.__index = self
    
    local size = w * h * 4
    
    for i = 0, size - 1 do 
        o.bytes[i] = 0
    end
    
    return o
end

function RGBAByteArray:set(x, y, color)
    local index = y * self.width * 4 + x * 4
    self.bytes[index] = color.red
    self.bytes[index + 1] = color.green
    self.bytes[index + 2] = color.blue
    self.bytes[index + 3] = color.alpha
end

function RGBAByteArray:toHexArray()
    local data = {}
    
    for i = 0, #self.bytes - 1 do
        data[i] = string.format("%02x", self.bytes[i])
    end
    
    return data
end
