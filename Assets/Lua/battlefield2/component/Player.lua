local class = require "utils.class"

local M = class();

function M:_init_(pid, level, name)
    self.pid   = pid; 
    self.level = level;
    self.name  = name;
end

function M:Serialize()
    return {self.pid, self.level, self.name}
end

function M:DeSerialize(data)
    self.pid, self.level, self.name = data[1], data[2], data[3]
end

return M;
