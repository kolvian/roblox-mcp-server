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

local function deserializeValue(value: any): any
	-- Handle special serialized types
	if typeof(value) == "table" and value._type then
		local valueType = value._type

		if valueType == "Vector3" then
			return Vector3.new(value.X or 0, value.Y or 0, value.Z or 0)
		elseif valueType == "Vector2" then
			return Vector2.new(value.X or 0, value.Y or 0)
		elseif valueType == "Color3" then
			return Color3.new(value.R or 0, value.G or 0, value.B or 0)
		elseif valueType == "CFrame" then
			local pos = value.Position or { X = 0, Y = 0, Z = 0 }
			local rot = value.Rotation or { X = 0, Y = 0, Z = 0 }
			return CFrame.new(pos.X, pos.Y, pos.Z)
				* CFrame.Angles(math.rad(rot.X), math.rad(rot.Y), math.rad(rot.Z))
		elseif valueType == "UDim2" then
			local x = value.X or { Scale = 0, Offset = 0 }
			local y = value.Y or { Scale = 0, Offset = 0 }
			return UDim2.new(x.Scale, x.Offset, y.Scale, y.Offset)
		elseif valueType == "Instance" then
			-- Try to resolve the instance by path
			if value.Path then
				return resolvePathToInstance(value.Path)
			end
			return nil
		elseif valueType == "Enum" then
			-- Try to resolve enum
			if value.EnumType and value.Name then
				local enumType = (Enum :: any)[value.EnumType]
				if enumType then
					return enumType[value.Name]
				end
			end
			return nil
		end
	end

	-- Return value as-is for primitives
	return value
end

local function setProperties(path: string, properties: any): string
	local instance = resolvePathToInstance(path)
	if not instance then
		return "Error: Could not find instance at path '" .. path .. "'"
	end

	if typeof(properties) ~= "table" then
		return "Error: Properties must be a table/object"
	end

	local results = {
		Path = instance:GetFullName(),
		ClassName = instance.ClassName,
		Success = {},
		Errors = {},
	}

	for propName, propValue in pairs(properties) do
		-- Skip internal fields
		if type(propName) == "string" and not propName:match("^_") then
			local deserializedValue = deserializeValue(propValue)

			local success, err = pcall(function()
				(instance :: any)[propName] = deserializedValue
			end)

			if success then
				table.insert(results.Success, propName)
			else
				results.Errors[propName] = tostring(err)
			end
		end
	end

	local summary = string.format(
		"Set %d propert%s successfully",
		#results.Success,
		#results.Success == 1 and "y" or "ies"
	)

	if next(results.Errors) then
		local errorCount = 0
		for _ in pairs(results.Errors) do
			errorCount += 1
		end
		summary ..= string.format(", %d error%s", errorCount, errorCount == 1 and "" or "s")
	end

	results.Summary = summary

	return HttpService:JSONEncode(results)
end

local function handleSetProperties(args: Types.ToolArgs): string?
	if not args["SetProperties"] then
		return nil
	end

	local setArgs: Types.SetPropertiesArgs = args["SetProperties"]
	if type(setArgs.path) ~= "string" then
		return "Error: Missing path in SetProperties"
	end

	if not setArgs.properties then
		return "Error: Missing properties in SetProperties"
	end

	local success, result = pcall(setProperties, setArgs.path, setArgs.properties)

	if not success then
		return "Error setting properties: " .. tostring(result)
	end

	return result
end

return handleSetProperties :: Types.ToolFunction
