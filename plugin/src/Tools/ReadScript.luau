local Main = script:FindFirstAncestor("MCPStudioPlugin")
local Types = require(Main.Types)

local function resolvePathToInstance(path: string): Instance?
	-- Start from game
	local current: Instance = game

	-- Handle "game" prefix
	if path:lower():sub(1, 4) == "game" then
		path = path:sub(5)
		if path:sub(1, 1) == "." then
			path = path:sub(2)
		end
	end

	-- If path is empty, return game
	if path == "" or path == "." then
		return game
	end

	-- Split by dots and traverse
	for part in path:gmatch("[^%.]+") do
		local found = current:FindFirstChild(part)
		if not found then
			return nil
		end
		current = found
	end

	return current
end

local function readScript(path: string): string
	local instance = resolvePathToInstance(path)

	if not instance then
		return "Error: Could not find instance at path '" .. path .. "'"
	end

	if not instance:IsA("LuaSourceContainer") then
		return "Error: Instance at path '"
			.. path
			.. "' is a "
			.. instance.ClassName
			.. ", not a Script, LocalScript, or ModuleScript"
	end

	local script: LuaSourceContainer = instance :: any
	return script.Source
end

local function handleReadScript(args: Types.ToolArgs): string?
	if not args["ReadScript"] then
		return nil
	end

	local readScriptArgs: Types.ReadScriptArgs = args["ReadScript"]
	if type(readScriptArgs.path) ~= "string" then
		return "Error: Missing path in ReadScript"
	end

	local success, result = pcall(readScript, readScriptArgs.path)
	if not success then
		return "Error reading script: " .. tostring(result)
	end

	return result
end

return handleReadScript :: Types.ToolFunction
