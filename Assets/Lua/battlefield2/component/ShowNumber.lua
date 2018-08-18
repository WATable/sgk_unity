local class = require "utils.class"

local M = class();

function M:_init_(uuid, value, type, name)
    self.uuid = uuid; 
    self.value = value;
    self.type = type;
    self.name = name;
end

function M:Serialize()
    return {self.uuid, self.value, self.type, self.name};
end

function M:DeSerialize(data)
    self.uuid, self.value, self.type, self.name = data[1], data[2], data[3], data[4];
end

return M;
