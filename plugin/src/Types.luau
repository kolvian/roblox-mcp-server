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

export type ToolArgs =
	{ InsertModel: InsertModelArgs }
	| { RunCode: RunCodeArgs }
	| { ListTree: ListTreeArgs }
	| { ReadScript: ReadScriptArgs }
	| { WriteScript: WriteScriptArgs }

export type ToolFunction = (ToolArgs) -> string?

return {}
