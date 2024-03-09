-- DebrisGobbler
-- by verret001

--[=[
	@class DebrisGobbler

	This module is a drop-in substitute for DebrisService that offers several significant performance and usability improvements.

	DebrisGobbler is much faster than DebrisService. While the DebrisService iterates through every item during each frame, resulting in up to 1000 iterations per frame or 60,000 iterations per second, this module only checks the nearest item to destruction per frame. 

	DebrisService has more problems that stem from this poor performance such as a preset limit on the number of debris items it can handle (which is 1000 by default), this causes problems such as Debris being destroyed before their expiry time. It also uses the old Roblox scheduler, which means 

	Despite these performance improvements, this module retains all of the advantages of DebrisService, such as not creating a new thread or coroutine for each new item and not holding onto destroyed items.

	To achieve this, the module utilizes a min-heap and some clever strategies to optimize the clearing of debris. The module is also strongly typed and offers some additional features on top of the original DebrisSevice such as DebrisGobbler:RemoveItem(Item).
]=]

local DebrisGobbler: DebrisGobbler = {}
local ExpiryReferences: ExpiryReferences = {}
local InstanceReferences: InstanceReferences = {}

local BinaryHeap = require(script.Parent.BinaryHeap)

local DebrisHeap = BinaryHeap.new(function(a, b)
	return (a < b)
end)

local pairs, clock, ceil, setmetatable = pairs, os.clock, math.ceil, setmetatable

--[=[
	This flag determines if a instance is destroyed before it's expiration
	This makes insertions slower as we need to form a connection to Destroying.
	This is only useful if you have *very* long expiration times
]=]
DebrisGobbler.EARLY_DESTRUCTION_CLEARING = false

--[=[
	This flag determines the maximum accuracy where nodes should be combined.
	In normal scenarios this should be 60, unless you are running this on a client with an FPS unlocker
	where you need the exact frame accuracy.
]=]
DebrisGobbler.MAX_FPS = 60

--[=[
    Initializes DebrisGobbler, ensure this is run on a script that will not be destroyed.

    @return nil
]=]

function DebrisGobbler:Init()
	if self.Connection then
		self.Connection:Disconnect()
	end
	self.Connection = game:GetService("RunService").Heartbeat:Connect(function()
		local Node: Node | nil, Value: number = DebrisHeap:peek()
		local currentTime: number = clock() + (1 / self.MAX_FPS)

		if Node and Value < currentTime then
			ExpiryReferences[Node] = nil
			DebrisHeap:pop()

			for Item: Instance, _ in pairs(Node["Instances"]) do
				-- mmm trash, I love trash
				Item:Destroy()
				if self.EARLY_DESTRUCTION_CLEARING then
					local Item = Node["Instances"][Item]
					if typeof(Item) == "RBXScriptConnection" then
						Item:Disconnect()
					end
				end
				Node["Instances"][Item] = nil
				InstanceReferences[Item] = nil
			end
		end
	end)
end

--[=[
    Adds an item to be destroyed in a specific amount of time.

    @param Item Instance -- The instance to destroy
    @param Time number -- The delta time to destruction Default: 7
    @return number -- Returns the CPU time of destruction
]=]
function DebrisGobbler:AddItem(Item: Instance, Time: number?): number
	assert(typeof(Item) == "Instance", "Invalid argument #1, expected type Instance")
	assert(typeof(Time) == "number" or Time == nil, "Invalid argument #2, expected type number?")
	if not self.Connection or self.Connection.Connected == false then
		warn(
			"DebrisGobbler.Connection disconnected due to likely script destruction. Ensure DebrisGobbler:Init() is on a persistent script."
		)
		self:Init()
	end

	-- We're locked to 60fps, so we can save on # of nodes by rounding to the next nearest frame.
	local ExpiryTime: number = ceil((clock() + (Time or 7)) * self.MAX_FPS) / self.MAX_FPS

	if InstanceReferences[Item] then
		return ExpiryTime
	end

	local Node: Node = ExpiryReferences[ExpiryTime]

	if Node == nil then
		Node = { ["n"] = 0, ["Instances"] = {} } :: Node
		ExpiryReferences[ExpiryTime] = Node
		DebrisHeap:insert(ExpiryTime, Node)
	end

	Node["Instances"][Item] = if self.EARLY_DESTRUCTION_CLEARING
		then Item.Destroying:Connect(function()
			self:RemoveItem(Item)
		end)
		else true

	InstanceReferences[Item] = Node
	Node["n"] += 1

	return ExpiryTime
end

--[=[
    Removes an item from any destruction queues.

    @param Item Instance -- The instance to remove from the destruction queue
    @return boolean -- Returns if the item was removed from the queue
]=]
function DebrisGobbler:RemoveItem(Item: Instance): boolean
	assert(typeof(Item) == "Instance", "Invalid argument #1, expected type Instance")
	local Node: Node = InstanceReferences[Item]
	if Node then
		if self.EARLY_DESTRUCTION_CLEARING then
			local Item = Node["Instances"][Item]
			if typeof(Item) == "RBXScriptConnection" then
				Item:Disconnect()
			end
		end

		Node["Instances"][Item] = nil
		InstanceReferences[Item] = nil

		Node["n"] -= 1
		if Node["n"] == 0 then
			DebrisHeap:removeNode(Node)
			ExpiryReferences[Node] = nil
		end
	end

	return not not Node
end

type Node = { ["Instances"]: { [Instance]: boolean | RBXScriptConnection }, ["n"]: number }
type ExpiryReferences = { [number]: Node }
type InstanceReferences = { [Instance]: Node }
type DebrisGobbler = typeof(DebrisGobbler)

return DebrisGobbler :: DebrisGobbler
