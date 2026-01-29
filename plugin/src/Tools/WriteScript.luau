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

local function parsePathParts(path: string): { string }
	local parts = {}

	-- Handle "game" prefix
	if path:lower():sub(1, 4) == "game" then
		path = path:sub(5)
		if path:sub(1, 1) == "." then
			path = path:sub(2)
		end
	end

	-- Split by dots
	for part in path:gmatch("[^%.]+") do
		table.insert(parts, part)
	end

	return parts
end

local function writeScript(path: string, source: string): string
	local instance = resolvePathToInstance(path)

	-- If instance exists, update it
	if instance then
		if not instance:IsA("LuaSourceContainer") then
			return "Error: Instance at path '"
				.. path
				.. "' is a "
				.. instance.ClassName
				.. ", not a Script, LocalScript, or ModuleScript"
		end

		local script: LuaSourceContainer = instance :: any
		script.Source = source
		return "Successfully updated script at '" .. path .. "'"
	end

	-- Instance doesn't exist, try to create it
	local parts = parsePathParts(path)
	if #parts < 2 then
		return "Error: Path '" .. path .. "' is too short. Need at least parent and script name."
	end

	-- Get parent path and script name
	local scriptName = parts[#parts]
	table.remove(parts, #parts)
	local parentPath = "game." .. table.concat(parts, ".")

	local parent = resolvePathToInstance(parentPath)
	if not parent then
		return "Error: Could not find parent at path '" .. parentPath .. "'"
	end

	-- Create a ModuleScript by default
	local newScript = Instance.new("ModuleScript")
	newScript.Name = scriptName
	newScript.Source = source
	newScript.Parent = parent

	return "Successfully created new script at '" .. path .. "'"
end

local function handleWriteScript(args: Types.ToolArgs): string?
	if not args["WriteScript"] then
		return nil
	end

	local writeScriptArgs: Types.WriteScriptArgs = args["WriteScript"]
	if type(writeScriptArgs.path) ~= "string" then
		return "Error: Missing path in WriteScript"
	end
	if type(writeScriptArgs.source) ~= "string" then
		return "Error: Missing source in WriteScript"
	end

	local success, result = pcall(writeScript, writeScriptArgs.path, writeScriptArgs.source)
	if not success then
		return "Error writing script: " .. tostring(result)
	end

	return result
end

return handleWriteScript :: Types.ToolFunction
