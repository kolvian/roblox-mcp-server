local Main = script:FindFirstAncestor("MCPStudioPlugin")
local Types = require(Main.Types)

local HttpService = game:GetService("HttpService")

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

local function serializeInstance(instance: Instance, currentDepth: number, maxDepth: number): any
	local result = {
		Name = instance.Name,
		ClassName = instance.ClassName,
		Path = instance:GetFullName(),
	}

	-- Add script-specific properties
	if instance:IsA("LuaSourceContainer") then
		result.IsScript = true
		result.SourceLength = #(instance :: any).Source
	end

	-- Recursively add children if we haven't reached max depth
	if currentDepth < maxDepth then
		local children = {}
		for _, child in instance:GetChildren() do
			table.insert(children, serializeInstance(child, currentDepth + 1, maxDepth))
		end
		if #children > 0 then
			result.Children = children
		end
	else
		-- Just note if there are children
		local childCount = #instance:GetChildren()
		if childCount > 0 then
			result.ChildCount = childCount
		end
	end

	return result
end

local MAX_OUTPUT_SIZE = 50000 -- 50KB limit to avoid overwhelming the client

local function createSimpleSummary(instance: Instance, maxDepth: number): string
	-- Create a simpler text-based summary instead of full JSON
	local lines = {}
	local function traverse(inst: Instance, depth: number, prefix: string)
		if depth > maxDepth then
			return
		end

		local icon = if inst:IsA("LuaSourceContainer") then "📜" else "📁"
		local info = icon .. " " .. inst.Name .. " (" .. inst.ClassName .. ")"
		if inst:IsA("LuaSourceContainer") then
			info ..= " [" .. #(inst :: any).Source .. " chars]"
		end
		table.insert(lines, prefix .. info)

		local children = inst:GetChildren()
		if #children > 50 and depth == 0 then
			-- Too many children at root level, just show count
			table.insert(lines, prefix .. "  ... and " .. #children .. " more children (use more specific path)")
			return
		end

		for i, child in children do
			if i > 100 then
				table.insert(lines, prefix .. "  ... and " .. (#children - 100) .. " more children")
				break
			end
			traverse(child, depth + 1, prefix .. "  ")
		end
	end

	traverse(instance, 0, "")
	return table.concat(lines, "\n")
end

local function listTree(path: string?, depth: number?): string
	local startPath = path or "game"
	local maxDepth = depth or 3

	local instance = resolvePathToInstance(startPath)
	if not instance then
		return "Error: Could not find instance at path '" .. startPath .. "'"
	end

	-- Try full JSON first
	local tree = serializeInstance(instance, 0, maxDepth)
	local jsonOutput = HttpService:JSONEncode(tree)

	-- If output is too large, return a simpler summary
	if #jsonOutput > MAX_OUTPUT_SIZE then
		local summary = createSimpleSummary(instance, maxDepth)
		return "Output too large (" .. #jsonOutput .. " chars), showing simplified summary:\n\n" .. summary
	end

	return jsonOutput
end

local function handleListTree(args: Types.ToolArgs): string?
	if not args["ListTree"] then
		return nil
	end

	local listTreeArgs: Types.ListTreeArgs = args["ListTree"]

	local success, result = pcall(listTree, listTreeArgs.path, listTreeArgs.depth)
	if not success then
		return "Error listing tree: " .. tostring(result)
	end

	return result
end

return handleListTree :: Types.ToolFunction
