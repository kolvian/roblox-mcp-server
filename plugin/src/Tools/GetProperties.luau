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

-- Common properties to read if none specified
local COMMON_PROPERTIES = {
	"Name",
	"ClassName",
	"Parent",
	-- BasePart properties
	"Position",
	"Size",
	"Rotation",
	"Transparency",
	"Color",
	"Material",
	"Anchored",
	"CanCollide",
	-- Model properties
	"PrimaryPart",
	-- GUI properties
	"Visible",
	"BackgroundColor3",
	"BackgroundTransparency",
	"Text",
	"TextColor3",
	"Font",
	"TextSize",
}

local function serializeValue(value: any): any
	local valueType = typeof(value)

	if valueType == "Instance" then
		return {
			_type = "Instance",
			Path = value:GetFullName(),
			ClassName = value.ClassName,
		}
	elseif valueType == "Vector3" then
		return {
			_type = "Vector3",
			X = value.X,
			Y = value.Y,
			Z = value.Z,
		}
	elseif valueType == "Vector2" then
		return {
			_type = "Vector2",
			X = value.X,
			Y = value.Y,
		}
	elseif valueType == "Color3" then
		return {
			_type = "Color3",
			R = value.R,
			G = value.G,
			B = value.B,
		}
	elseif valueType == "CFrame" then
		local pos = value.Position
		local x, y, z = value:ToEulerAnglesXYZ()
		return {
			_type = "CFrame",
			Position = { X = pos.X, Y = pos.Y, Z = pos.Z },
			Rotation = { X = math.deg(x), Y = math.deg(y), Z = math.deg(z) },
		}
	elseif valueType == "UDim2" then
		return {
			_type = "UDim2",
			X = { Scale = value.X.Scale, Offset = value.X.Offset },
			Y = { Scale = value.Y.Scale, Offset = value.Y.Offset },
		}
	elseif valueType == "EnumItem" then
		return {
			_type = "Enum",
			EnumType = tostring(value.EnumType),
			Name = value.Name,
			Value = value.Value,
		}
	end

	return value
end

local function getProperties(path: string, properties: { string }?): string
	local instance = resolvePathToInstance(path)
	if not instance then
		return "Error: Could not find instance at path '" .. path .. "'"
	end

	local propsToRead = properties or COMMON_PROPERTIES
	local result = {
		Path = instance:GetFullName(),
		ClassName = instance.ClassName,
		Properties = {},
	}

	for _, propName in ipairs(propsToRead) do
		local success, value = pcall(function()
			return (instance :: any)[propName]
		end)

		if success then
			result.Properties[propName] = serializeValue(value)
		else
			-- Property doesn't exist or can't be read
			result.Properties[propName] = {
				_type = "Error",
				_error = "Property not readable or doesn't exist",
			}
		end
	end

	return HttpService:JSONEncode(result)
end

local function handleGetProperties(args: Types.ToolArgs): string?
	if not args["GetProperties"] then
		return nil
	end

	local getArgs: Types.GetPropertiesArgs = args["GetProperties"]
	if type(getArgs.path) ~= "string" then
		return "Error: Missing path in GetProperties"
	end

	local success, result = pcall(getProperties, getArgs.path, getArgs.properties)

	if not success then
		return "Error getting properties: " .. tostring(result)
	end

	return result
end

return handleGetProperties :: Types.ToolFunction
