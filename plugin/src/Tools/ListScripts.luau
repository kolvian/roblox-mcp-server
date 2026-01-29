local Main = script:FindFirstAncestor("MCPStudioPlugin")
local Types = require(Main.Types)

local HttpService = game:GetService("HttpService")

local function resolvePathToInstance(path: string): Instance?
	local current: Instance = game

	if path:lower():sub(1, 4) == "game" then
		path = path:sub(5)
		if path:sub(1, 1) == "." then
			path = path:sub(2)
		end
	end

	if path == "" or path == "." then
		return game
	end

	for part in path:gmatch("[^%.]+") do
		local found = current:FindFirstChild(part)
		if not found then
			return nil
		end
		current = found
	end

	return current
end

local function listScripts(path: string?, scriptType: string?): string
	local startPath = path or "game"
	local filterType = scriptType

	local startInstance = resolvePathToInstance(startPath)
	if not startInstance then
		return "Error: Could not find instance at path '" .. startPath .. "'"
	end

	local scripts = {}

	local function traverse(instance: Instance)
		if instance:IsA("LuaSourceContainer") then
			local script = instance :: LuaSourceContainer

			-- Check if we should include this script based on filter
			local shouldInclude = true
			if filterType then
				shouldInclude = script.ClassName == filterType
			end

			if shouldInclude then
				table.insert(scripts, {
					Path = script:GetFullName(),
					Name = script.Name,
					ClassName = script.ClassName,
					SourceLength = #script.Source,
					Parent = script.Parent and script.Parent:GetFullName() or "nil",
				})
			end
		end

		for _, child in instance:GetChildren() do
			traverse(child)
		end
	end

	traverse(startInstance)

	-- Sort by path
	table.sort(scripts, function(a, b)
		return a.Path < b.Path
	end)

	if #scripts == 0 then
		local typeMsg = if filterType then " of type " .. filterType else ""
		return "No scripts found" .. typeMsg .. " in " .. startPath
	end

	-- Return as JSON for easy parsing
	return HttpService:JSONEncode({
		count = #scripts,
		scripts = scripts,
	})
end

local function handleListScripts(args: Types.ToolArgs): string?
	if not args["ListScripts"] then
		return nil
	end

	local listArgs: Types.ListScriptsArgs = args["ListScripts"]

	local success, result = pcall(listScripts, listArgs.path, listArgs.script_type)

	if not success then
		return "Error listing scripts: " .. tostring(result)
	end

	return result
end

return handleListScripts :: Types.ToolFunction
