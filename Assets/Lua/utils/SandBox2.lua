-- assert(setfenv == nil, "need lua version >= 5.2")

local ThreadCounter = {};
function ThreadCounter.New(count) 
	return setmetatable({count = count or 0, main = coroutine.running()}, {__index=ThreadCounter});
end

function ThreadCounter:Retain()
	self.count = self.count + 1;
end

function ThreadCounter:Release(force)
	local co = coroutine.running();
	self.count = self.count - 1;
	if force or self.count <= 0 then
		if co == self.main then
			return;
		else
			local success, info = coroutine.resume(self.main);
			if not success then
				ERROR_LOG(info, debug.traceback());
			end
		end
	else
		if co == self.main then
			coroutine.yield();
		end
	end
end

local __api_count = 0;

local SandBox = {}

local script_env_index = nil
if UnityEngine and UnityEngine.Application.isEditor then
    script_env_index = function(t, k)
        if SandBox[k] ~= nil then return SandBox[k] end

        local v = t.__importValues[k];

        if type(v) ~= "function" then return v; end

        return setmetatable({}, {__call=function(_, ...)
            __api_count = __api_count + 1;
            if __api_count >= 1000 then
                assert(__api_count < 1000, 
                    string.format("too much api [%s] call in script\n%s",
                        k, debug.traceback()));
            end
            return v(...);
        end})
    end
else
    script_env_index = function(t, k)
        return SandBox[k] or t.__importValues[k];
    end
end

function SandBox.New(fileName, importValues)
    local env = setmetatable({
		table = table,
		math  = math,
		string = string,
		ipairs = ipairs,
		pairs = pairs,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = table.unpack or unpack,
		select = select,
		next = next,
		assert = assert,

		print = print,

		debug = debug,

		__importValues = importValues or {},
		__thread_counter = nil,
		__cos = {},
	}, {__index=script_env_index});

	env.Run = function(func, ...)
		local threadCounter = env.__thread_counter;

		threadCounter:Retain();

		local co = coroutine.create(function()
			func();
			threadCounter:Release();
		end);

		-- save coroutine to avoid gc
		local idx = #env.__cos + 1;
		table.insert(env.__cos, co);

		local success, info = coroutine.resume(co, ...);
		if not success then
			ERROR_LOG(info, debug.traceback());
			threadCounter:Release();
		end

		-- remove from coroutine list
		env.__cos[idx] = nil;
	end

	env._script_file_not_exists = false;
	local chunk, info = loadfile(fileName, "bt", env);
	if chunk == nil then
		print('loadfile', fileName, "failed", info, debug.traceback());
		chunk = function() print("script error", fileName, info) end
		env._script_file_not_exists = true;
	end

	if setfenv then
		setfenv(chunk, env)
	end

	env.__chunk = chunk;
	env.__thread_counter = nil;
	env.__file = fileName;

	return env;
end


local function getGlobalLibrary(scriptFileName, game)
	game.__scriptLibrary = game.__scriptLibrary or {}

	local scriptLibrary = game.__scriptLibrary;

	if scriptLibrary[scriptFileName] then
		return scriptLibrary[scriptFileName]
	end

	local env_metatable = {
		__index = function(t, k)
			if t.__lib[k] then return t.__lib[k] end;
			if game.API[k] then return game.API[k] end;
			ERROR_LOG('canot read sandbox var', k, 'by ' .. scriptFileName, debug.traceback());
		end,
		__newindex = function(t, k, v)
			-- print(scriptFileName, 'set library value ', k, v);
			rawset(t.__lib, k, v)
		end
	}

	local env = setmetatable({
		table = table,
		math  = math,
		string = string,
		ipairs = ipairs,
		pairs = pairs,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		unpack = table.unpack or unpack,
		select = select,
		next = next,
		assert = assert,

		print = print,
		debug = debug,
		__lib = {},
	}, env_metatable);
	
	local func = assert(loadfile(scriptFileName, 'bt', env))
	if setfenv then setfenv(func, env); end

	func();

	env_metatable.__newindex = function(t, k, v)
		ERROR_LOG('canot set global value', k, 'by' .. scriptFileName, debug.traceback())
	end

	scriptLibrary[scriptFileName] = env.__lib;
	
	-- print('ENV', env, scriptFileName);

	return env.__lib;
end

function SandBox:LoadLib(scriptFileName, game)
	if game then
		-- print('SandBox:AddLib', self.__file, scriptFileName)
		return self:AddLib(getGlobalLibrary(scriptFileName, game))
	end

	local func = assert(loadfile(scriptFileName, 'bt', self))

	if setfenv then
		setfenv(func, self);
	end

	func();
end

function SandBox:AddLib(library)
	for k, v in pairs(library or {}) do
		--[[
		if self.__importValues[k] then
			ERROR_LOG('duplicate library value', k, v, self.__importValues[k])
		end
		--]]
		-- print('set library value', k, v, self.__importValues[k])
		self.__importValues[k] = v;
	end
end

function SandBox:Detach()
	self.__thread_counter:Release(true);
end

local safe_call = setfenv and function(func, ...)
	local success, v1, v2, v3 = pcall(func, ...) 
	if not success then
		print(v1);
	end
	return success, v1, v2, v3
end or function(func, ...)
	return xpcall(func, function(...)
		print(..., debug.traceback());
	end, ...)
end

function SandBox:Call(...)
	self.__thread_counter = ThreadCounter.New(1);

	__api_count = 0;

	local success, v1, v2, v3;
	if UnityEngine then
		success, v1, v2, v3 = xpcall(self.__chunk, function(...)
			ERROR_LOG(..., debug.traceback());
		end, ...)
	else
		success, v1, v2, v3 = pcall(self.__chunk, ...)
		if not success then
			ERROR_LOG(v1);
		end
	end

	self.__thread_counter:Release();

	if success then
		return v1, v2, v3;
	else
		return false;
	end
end


return {
	New = SandBox.New,
	ThreadCounter = ThreadCounter,
}
