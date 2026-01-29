local Main = script:FindFirstAncestor("MCPStudioPlugin")
local Types = require(Main.Types)

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

local function escapePattern(str: string): string
	-- Escape special regex characters for plain text search
	return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

local function searchScripts(
	pattern: string,
	path: string?,
	caseSensitive: boolean?,
	useRegex: boolean?
): string
	local startPath = path or "game"
	local isCaseSensitive = if caseSensitive ~= nil then caseSensitive else false
	local isRegex = if useRegex ~= nil then useRegex else false

	local startInstance = resolvePathToInstance(startPath)
	if not startInstance then
		return "Error: Could not find instance at path '" .. startPath .. "'"
	end

	-- Prepare the pattern
	local searchPattern = pattern
	if not isRegex then
		searchPattern = escapePattern(pattern)
	end
	if not isCaseSensitive then
		searchPattern = searchPattern:lower()
	end

	local matches = {}
	local scriptCount = 0
	local MAX_MATCHES = 500 -- Limit to prevent overwhelming output

	local function searchInScript(script: LuaSourceContainer)
		scriptCount += 1
		local source = script.Source
		local searchSource = if isCaseSensitive then source else source:lower()

		-- Split into lines
		local lines = {}
		for line in (source .. "\n"):gmatch("([^\n]*)\n") do
			table.insert(lines, line)
		end

		-- Search each line
		for lineNum, lineContent in ipairs(lines) do
			local searchLine = if isCaseSensitive then lineContent else lineContent:lower()
			local found = if isRegex then searchLine:match(searchPattern) else searchLine:find(searchPattern, 1, true)

			if found and #matches < MAX_MATCHES then
				table.insert(matches, {
					script = script:GetFullName(),
					line = lineNum,
					content = lineContent:gsub("^%s+", ""), -- Trim leading whitespace
				})
			end
		end
	end

	local function traverse(instance: Instance)
		if instance:IsA("LuaSourceContainer") then
			searchInScript(instance :: LuaSourceContainer)
		end

		for _, child in instance:GetChildren() do
			traverse(child)
		end
	end

	traverse(startInstance)

	-- Format results
	if #matches == 0 then
		return string.format(
			"No matches found for pattern '%s' in %d script(s)",
			pattern,
			scriptCount
		)
	end

	local resultLines = {
		string.format("Found %d match(es) in %d script(s):", #matches, scriptCount),
		"",
	}

	-- Group by script
	local byScript = {}
	for _, match in ipairs(matches) do
		if not byScript[match.script] then
			byScript[match.script] = {}
		end
		table.insert(byScript[match.script], match)
	end

	for scriptPath, scriptMatches in pairs(byScript) do
		table.insert(resultLines, "📜 " .. scriptPath)
		for _, match in ipairs(scriptMatches) do
			table.insert(
				resultLines,
				string.format("  Line %d: %s", match.line, match.content)
			)
		end
		table.insert(resultLines, "")
	end

	if #matches >= MAX_MATCHES then
		table.insert(resultLines, string.format("(Limited to first %d matches)", MAX_MATCHES))
	end

	return table.concat(resultLines, "\n")
end

local function handleSearchScripts(args: Types.ToolArgs): string?
	if not args["SearchScripts"] then
		return nil
	end

	local searchArgs: Types.SearchScriptsArgs = args["SearchScripts"]
	if type(searchArgs.pattern) ~= "string" then
		return "Error: Missing pattern in SearchScripts"
	end

	local success, result = pcall(
		searchScripts,
		searchArgs.pattern,
		searchArgs.path,
		searchArgs.case_sensitive,
		searchArgs.use_regex
	)

	if not success then
		return "Error searching scripts: " .. tostring(result)
	end

	return result
end

return handleSearchScripts :: Types.ToolFunction
