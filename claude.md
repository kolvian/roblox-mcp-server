# Claude Development Best Practices for This Project

## 🚫 CRITICAL RULES - NEVER VIOLATE THESE

### UI/GUI Instantiation
**NEVER ad-hoc instantiate new GUI instances when creating scripts and behavior.**
- ❌ NEVER use `Instance.new()` to create UI elements (ScreenGui, Frame, TextLabel, BillboardGui, etc.)
- ✅ ALWAYS use existing GUI templates from the project
- ✅ ALWAYS clone existing GUIs: `existingGui:Clone()`
- ❓ If no existing GUI exists, **ASK FOR CLARIFICATION** before creating anything

**Example - WRONG:**
```lua
local gui = Instance.new("ScreenGui")  -- ❌ NEVER DO THIS
local frame = Instance.new("Frame")    -- ❌ NEVER DO THIS
```

**Example - CORRECT:**
```lua
local template = script:FindFirstChild("GuiTemplate")  -- ✅ Use existing
local gui = template:Clone()                            -- ✅ Clone it
```

### Script Location
**Scripts should ONLY exist in these locations:**
- ✅ `StarterPlayer.StarterPlayerScripts` (client scripts)
- ✅ `StarterPlayer.StarterCharacterScripts` (character scripts)
- ✅ `ServerScriptService` (server scripts)
- ❌ NEVER put scripts in `Workspace` (except for very specific cases like temporary test scripts)
- ❌ NEVER put scripts in `ReplicatedStorage` (only ModuleScripts go there)

### Script Types by Location
- **LocalScripts** → `StarterPlayer.StarterPlayerScripts` or `StarterPlayer.StarterCharacterScripts`
- **Scripts (Server)** → `ServerScriptService`
- **ModuleScripts** → Can be anywhere, but prefer:
  - `ReplicatedStorage` for shared modules (client + server)
  - `ServerScriptService` for server-only modules
  - `StarterPlayer.StarterPlayerScripts` for client-only modules

### Networking Pattern
**ALWAYS use the custom Remotes wrapper at `ReplicatedStorage.SharedPackages.Remotes`**
- ❌ NEVER use `Instance.new("RemoteEvent")` or `Instance.new("RemoteFunction")`
- ❌ NEVER directly reference RemoteEvents/RemoteFunctions in the DataModel
- ✅ ALWAYS use the centralized Remotes module
- ✅ Add new remotes to the Remotes module itself, organized by namespace

**Example - WRONG:**
```lua
local event = Instance.new("RemoteEvent")  -- ❌ NEVER DO THIS
event.Parent = ReplicatedStorage
event:FireClient(player, data)
```

**Example - CORRECT:**
```lua
local Remotes = require(game:GetService("ReplicatedStorage").SharedPackages.Remotes)

-- Server
Remotes.Inventory.ItemDropped.OnServerEvent:Connect(function(player, ...)
    -- Handle event
end)

-- Client
Remotes.Inventory.ModifyInventory.OnClientEvent:Connect(function(data)
    -- Handle event
end)
```

**Adding New Remotes:**
To add new remotes, edit `ReplicatedStorage.SharedPackages.Remotes`:
```lua
local module = {
    MySystem = {
        MyEvent = getEvent("MyEventName"),
        MyFunction = getFunction("MyFunctionName"),
    }
}
```

**Organized by Namespace:**
- `Remotes.Inventory.*` - Inventory-related remotes
- `Remotes.Marketplace.*` - Market-related remotes
- `Remotes.Solari.*` - Currency-related remotes
- Add new namespaces for new systems

---

## 📋 General Best Practices

### Architecture Patterns
1. **Use ModuleScripts for organization**
   - Keep logic in modules with clear responsibilities
   - Main scripts should be thin controllers that require modules

2. **Client/Server Separation**
   - Client code in `StarterPlayer.StarterPlayerScripts`
   - Server code in `ServerScriptService`
   - Shared code in `ReplicatedStorage`
   - Communicate via RemoteEvents/RemoteFunctions

3. **GUI Management**
   - Store GUI templates as children of scripts or in `ReplicatedStorage`
   - Clone templates when needed
   - Never instantiate UI elements from scratch

### Roblox-Specific Patterns

#### Services
Always get services at the top of scripts:
```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
```

#### Networking
- **ALWAYS use the custom Remotes wrapper** (`ReplicatedStorage.SharedPackages.Remotes`)
- Never create RemoteEvents/RemoteFunctions directly with `Instance.new()`
- Add new remotes by editing the Remotes module itself

#### Wait for Children
- Use `:WaitForChild()` when accessing instances that may not exist yet
- Don't use `wait()` loops to check for existence

---

## 🎮 Project-Specific Conventions

### Folder Structure
```
StarterPlayer/
  StarterPlayerScripts/
    Client (LocalScript - main controller)
      ClientRun/ (Folder)
        [ModuleScripts for different systems]
      ClientPackages/ (Folder)
        [Utility modules]

ServerScriptService/
  Server (Script - main controller)
    ServerPackages/ (Folder)
      [Server utility modules]
    [System modules like Inventory, Marketplace]

ReplicatedStorage/
  SharedPackages/ (Folder)
    [Shared data modules]
  UtilPackages/ (Folder)
    [Shared utility modules]
  GlobalItems/ (Folder)
    [Item models]
```

### Module Pattern
All modules should:
1. Return a table
2. Have an `:Init()` function if they need initialization
3. Be required by the main controller script

```lua
local MyModule = {}

function MyModule:Init()
    -- Setup code here
end

function MyModule.DoSomething()
    -- Functionality here
end

return MyModule
```

### Initialization Pattern
Main controller scripts (`Client`, `Server`) should:
1. Require all modules
2. Call `:Init()` on modules that need it
3. Set up global connections/events

---

## 🔧 Common Patterns in This Project

### Custom Proximity Prompts
- ProximityPrompt Style set to `Custom`
- GUI template stored as child of Interact module
- Clone and parent to prompt.Parent when shown

### Inventory System
- ProfileService for data persistence
- ModuleScript-based with public functions
- Client receives updates via RemoteEvents

### Marketplace System
- MemoryStore for cross-server synchronization
- DataStore for persistence
- PrimaryServer handles shipments
- All servers sync via MessagingService

### Networking Examples

**Server → Client (RemoteEvent):**
```lua
-- Server
local Remotes = require(game:GetService("ReplicatedStorage").SharedPackages.Remotes)
Remotes.Marketplace.UpdateClient:FireAllClients(marketData)
-- or
Remotes.Inventory.LoadClientInventory:FireClient(player, inventoryData, equippedItems)
```

**Client Listening (RemoteEvent):**
```lua
-- Client
local Remotes = require(game:GetService("ReplicatedStorage").SharedPackages.Remotes)
Remotes.Marketplace.UpdateClient.OnClientEvent:Connect(function(newData)
    -- Handle update
end)
```

**Client → Server (RemoteEvent):**
```lua
-- Client
local Remotes = require(game:GetService("ReplicatedStorage").SharedPackages.Remotes)
Remotes.Marketplace.ClientPurchased:FireServer(itemId, quantity)
```

**Server Listening (RemoteEvent):**
```lua
-- Server
local Remotes = require(game:GetService("ReplicatedStorage").SharedPackages.Remotes)
Remotes.Marketplace.ClientPurchased.OnServerEvent:Connect(function(player, itemId, quantity)
    -- Handle purchase
end)
```

**Client → Server Request (RemoteFunction):**
```lua
-- Client
local Remotes = require(game:GetService("ReplicatedStorage").SharedPackages.Remotes)
local currentSolari = Remotes.Solari.Get:InvokeServer()
```

**Server Responding (RemoteFunction):**
```lua
-- Server
local Remotes = require(game:GetService("ReplicatedStorage").SharedPackages.Remotes)
Remotes.Solari.Get.OnServerInvoke = function(player)
    return Solari.GetSolari(player)
end
```

---

## ⚠️ Things to Avoid

1. **Don't instantiate UI from scratch** - Clone existing templates
2. **Don't create RemoteEvents/RemoteFunctions** - Use the Remotes wrapper
3. **Don't put scripts in Workspace** - Use StarterPlayer/ServerScriptService
4. **Don't use `wait()` for existence checks** - Use `:WaitForChild()`
5. **Don't scatter remotes** - Use centralized Remotes module
6. **Don't mix client/server code** - Keep them separate
7. **Don't forget error handling** - Use pcall for RemoteFunction calls
8. **Don't create circular dependencies** - Keep module dependencies one-way

---

## 📝 When in Doubt

**ALWAYS ASK FOR CLARIFICATION:**
- If you need to create UI and no template exists
- If you're unsure where a script should be located
- If you're not sure how to integrate with existing systems
- If the pattern doesn't match existing code in the project

**It's better to ask than to create something that doesn't follow project conventions!**
