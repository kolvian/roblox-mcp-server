export type InsertModelArgs = {
	query: string,
}

export type RunCodeArgs = {
	command: string,
}

export type ListTreeArgs = {
	path: string?,
	depth: number?,
}

export type ReadScriptArgs = {
	path: string,
}

export type WriteScriptArgs = {
	path: string,
	source: string,
}

export type SearchScriptsArgs = {
	pattern: string,
	path: string?,
	case_sensitive: boolean?,
	use_regex: boolean?,
}

export type ListScriptsArgs = {
	path: string?,
	script_type: string?,
}

export type GetPropertiesArgs = {
	path: string,
	properties: { string }?,
}

export type SetPropertiesArgs = {
	path: string,
	properties: any,
}

export type ToolArgs =
	{ InsertModel: InsertModelArgs }
	| { RunCode: RunCodeArgs }
	| { ListTree: ListTreeArgs }
	| { ReadScript: ReadScriptArgs }
	| { WriteScript: WriteScriptArgs }
	| { SearchScripts: SearchScriptsArgs }
	| { ListScripts: ListScriptsArgs }
	| { GetProperties: GetPropertiesArgs }
	| { SetProperties: SetPropertiesArgs }

export type ToolFunction = (ToolArgs) -> string?

return {}
