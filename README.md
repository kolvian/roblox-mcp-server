# Quick Setup
1. Download and Run the server: [Windows](https://github.com/Roblox/studio-rust-mcp-server/releases/latest/download/rbx-studio-mcp.exe) or [macOS](https://github.com/Roblox/studio-rust-mcp-server/releases/latest/download/macOS-rbx-studio-mcp.zip)
2. Restart AI Client (Claude, Cursor, etc) and Roblox Studio
3. Done!

# Roblox Studio MCP Server

This repository contains a reference implementation of the Model Context Protocol (MCP) that enables
communication between Roblox Studio via a plugin and [Claude Desktop](https://claude.ai/download) or [Cursor](https://www.cursor.com/).
It consists of the following Rust-based components, which communicate through internal shared
objects.

- A web server built on `axum` that a Studio plugin long polls.
- A `rmcp` server that talks to Claude via `stdio` transport.

When LLM requests to run a tool, the plugin will get a request through the long polling and post a
response. It will cause responses to be sent to the Claude app.

**Please note** that this MCP server will be accessed by third-party tools, allowing them to modify
and read the contents of your opened place. Third-party data handling and privacy practices are
subject to their respective terms and conditions.

![Scheme](MCP-Server.png)

The setup process also contains a short plugin installation and Claude Desktop configuration script.

## Setup

### Install with release binaries

This MCP Server supports pretty much any MCP Client but will automatically set up only [Claude Desktop](https://claude.ai/download) and [Cursor](https://www.cursor.com/) if found.

To set up automatically:

1. Ensure you have [Roblox Studio](https://create.roblox.com/docs/en-us/studio/setup),
   and [Claude Desktop](https://claude.ai/download)/[Cursor](https://www.cursor.com/) installed and started at least once.
1. Exit MCP Clients and Roblox Studio if they are running.
1. Download and run the installer:
   1. Go to the [releases](https://github.com/Roblox/studio-rust-mcp-server/releases) page and
      download the latest release for your platform.
   1. Unzip the downloaded file if necessary and run the installer.
   1. Restart Claude/Cursor and Roblox Studio if they are running.

### Setting up manually

To set up manually add following to your MCP Client config:

```json
{
  "mcpServers": {
    "Roblox Studio": {
      "args": [
        "--stdio"
      ],
      "command": "Path-to-downloaded\\rbx-studio-mcp.exe"
    }
  }
}
```

On macOS the path would be something like `"/Applications/RobloxStudioMCP.app/Contents/MacOS/rbx-studio-mcp"` if you move the app to the Applications directory.

### Build from source

To build and install the MCP reference implementation from this repository's source code:

1. Ensure you have [Roblox Studio](https://create.roblox.com/docs/en-us/studio/setup) and
   [Claude Desktop](https://claude.ai/download) installed and started at least once.
1. Exit Claude and Roblox Studio if they are running.
1. [Install](https://www.rust-lang.org/tools/install) Rust.
1. Download or clone this repository.
1. Run the following command from the root of this repository.
   ```sh
   cargo run
   ```
   This command carries out the following actions:
      - Builds the Rust MCP server app.
      - Sets up Claude to communicate with the MCP server.
      - Builds and installs the Studio plugin to communicate with the MCP server.

After the command completes, the Studio MCP Server is installed and ready for your prompts from
Claude Desktop.

## Verify setup

To make sure everything is set up correctly, follow these steps:

1. In Roblox Studio, click on the **Plugins** tab and verify that the MCP plugin appears. Clicking on
   the icon toggles the MCP communication with Claude Desktop on and off, which you can verify in
   the Roblox Studio console output.
1. In the console, verify that `The MCP Studio plugin is ready for prompts.` appears in the output.
   Clicking on the plugin's icon toggles MCP communication with Claude Desktop on and off,
   which you can also verify in the console output.
1. Verify that Claude Desktop is correctly configured by clicking on the hammer icon for MCP tools
   beneath the text field where you enter prompts. This should open a window with the list of
   available Roblox Studio tools (`run_code`, `insert_model`, `list_tree`, `read_script`, `write_script`, `search_scripts`, `list_scripts`, `get_properties`, and `set_properties`).

**Note**: You can fix common issues with setup by restarting Studio and Claude Desktop. Claude
sometimes is hidden in the system tray, so ensure you've exited it completely.

## Send requests

1. Open a place in Studio.
1. Type a prompt in Claude Desktop and accept any permissions to communicate with Studio.
1. Verify that the intended action is performed in Studio by checking the console, inspecting the
   data model in Explorer, or visually confirming the desired changes occurred in your place.

## Available Tools

This MCP server provides the following tools for interacting with Roblox Studio:

### `run_code`
Executes Lua code within Roblox Studio and returns the output.
- **Parameters:**
  - `command` (string): Lua code to execute
- **Returns:** Printed output, warnings, errors, and return values
- **Use cases:** Query data, make changes, inspect objects, test code snippets

### `insert_model`
Searches the Roblox marketplace and inserts free models into the workspace.
- **Parameters:**
  - `query` (string): Search term for the model
- **Returns:** Name of the inserted model
- **Use cases:** Quickly add assets from the Roblox library

### `list_tree`
Lists the Roblox instance hierarchy starting from a given path.
- **Parameters:**
  - `path` (string, optional): Starting path (e.g., `"game.Workspace"`, `"game.ServerScriptService"`). Defaults to `"game"`.
  - `depth` (number, optional): Maximum depth to traverse. Defaults to `3`.
- **Returns:** JSON tree structure with instance names, class types, and children
- **Use cases:** Explore the DataModel, understand project structure, find instances

### `read_script`
Reads the source code of a script instance.
- **Parameters:**
  - `path` (string): Path to the script (e.g., `"game.ServerScriptService.MyScript"`)
- **Returns:** Script source code
- **Use cases:** View script contents, analyze existing code, review implementations
- **Supported types:** Script, LocalScript, ModuleScript

### `write_script`
Writes or modifies script source code.
- **Parameters:**
  - `path` (string): Path to the script (e.g., `"game.ServerScriptService.MyScript"`)
  - `source` (string): New source code for the script
- **Returns:** Success message
- **Use cases:** Create new scripts, update existing code, refactor implementations
- **Supported types:** Script, LocalScript, ModuleScript
- **Note:** Creates a new ModuleScript if the path doesn't exist

### `search_scripts`
Searches for a pattern across all scripts in the game. Similar to Cmd+Shift+F in Roblox Studio or grep.
- **Parameters:**
  - `pattern` (string): Text or regex pattern to search for
  - `path` (string, optional): Starting path to search within. Defaults to entire game.
  - `case_sensitive` (boolean, optional): Whether search is case sensitive. Defaults to `false`.
  - `use_regex` (boolean, optional): Whether to use regex pattern matching. Defaults to `false`.
- **Returns:** List of matches with script paths, line numbers, and context
- **Use cases:** Find function definitions, find API usage, search for variables, locate TODO comments
- **Note:** Limited to 500 matches to prevent overwhelming output

### `list_scripts`
Returns a flat list of all scripts in the game with their paths and metadata.
- **Parameters:**
  - `path` (string, optional): Starting path to search within. Defaults to entire game.
  - `script_type` (string, optional): Filter by `"Script"`, `"LocalScript"`, or `"ModuleScript"`. Shows all if not provided.
- **Returns:** JSON array with script information (path, name, class, source length)
- **Use cases:** Get overview of all scripts, find scripts by name, audit script types

### `get_properties`
Reads property values from an instance.
- **Parameters:**
  - `path` (string): Path to the instance (e.g., `"game.Workspace.Part"`)
  - `properties` (array, optional): Specific properties to read. Returns common properties if not provided.
- **Returns:** JSON object with property values (properly serialized Vector3, Color3, CFrame, etc.)
- **Use cases:** Check positions, colors, transparency, sizes without writing Lua code
- **Supported types:** Handles Vector3, Color3, CFrame, UDim2, Enums, and primitives

### `set_properties`
Sets property values on an instance.
- **Parameters:**
  - `path` (string): Path to the instance (e.g., `"game.Workspace.Part"`)
  - `properties` (object): Key-value pairs of properties to set
- **Returns:** JSON with success/error status for each property
- **Use cases:** Quick property modifications without writing Lua code (positions, colors, transparency, etc.)
- **Note:** Accepts serialized values (e.g., `{"Position": {"_type": "Vector3", "X": 0, "Y": 5, "Z": 0}}`)

## Example Prompts

Here are some example prompts you can try with Claude:

**Exploring & Understanding:**
- "Show me the structure of my workspace" (uses `list_tree`)
- "List all the scripts in my game" (uses `list_scripts`)
- "Find all places where I use RemoteEvent:FireClient" (uses `search_scripts`)
- "Search for TODO comments in all scripts" (uses `search_scripts`)

**Reading & Analyzing:**
- "Read the MainScript in ServerScriptService" (uses `read_script`)
- "Show me the properties of Workspace.SpawnLocation" (uses `get_properties`)
- "What's the position and size of the Part named 'Door'?" (uses `get_properties`)

**Creating & Modifying:**
- "Create a new script that prints 'Hello World' every 5 seconds" (uses `write_script`)
- "Make the part at game.Workspace.Part transparent" (uses `set_properties`)
- "Change the position of Workspace.Part to (0, 10, 0)" (uses `set_properties`)
- "Modify the PlayerJoin script to give players 100 coins on spawn" (uses `read_script` + `write_script`)

**Adding Assets:**
- "Add a SpawnLocation to the workspace" (uses `insert_model` or `run_code`)

**Advanced:**
- "Find all scripts that handle player death" (uses `search_scripts`)
- "List all ModuleScripts in ReplicatedStorage" (uses `list_scripts` with filter)
- "Show me everywhere the function 'processPayment' is called" (uses `search_scripts` with regex)
