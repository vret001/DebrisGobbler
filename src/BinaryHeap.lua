local BinaryHeap = {}
BinaryHeap.__index = BinaryHeap

function BinaryHeap.new(lt)
	local self = setmetatable({
		values = {},
		lt = lt,
		nodes = {},
		reverse = {}
	}, BinaryHeap)
	
	return self
end

function BinaryHeap:erase(pos)
	local node = self.nodes[pos]
	self.reverse[node] = nil
	self.nodes[pos] = nil
	self.values[pos] = nil
end

function BinaryHeap:swap(a, b)
	local pla, plb = self.nodes[a], self.nodes[b]
	self.reverse[pla], self.reverse[plb] = b, a
	self.nodes[a], self.nodes[b] = plb, pla

	self.values[a], self.values[b] = self.values[b], self.values[a] -- swap(heap, a, b)
end

local floor = math.floor
function BinaryHeap:bubbleUp(pos)
	local values = self.values
	while pos > 1 do
		local parent = floor(pos / 2)
		if not self.lt(values[pos], values[parent]) then
			break
		end
		self:swap(parent, pos)
		pos = parent
	end
end

function BinaryHeap:sinkDown(pos)
	local values = self.values
	local last = #values
	while true do
		local min = pos
		local child = 2 * pos

		for c = child, child + 1 do
			if c <= last and self.lt(values[c], values[min]) then
				min = c
			end
		end

		if min == pos then
			break
		end

		self:swap(pos, min)
		pos = min
	end
end

function BinaryHeap:peek()
	return self.nodes[1], self.values[1]
end

function BinaryHeap:peekValue()
	return self.values[1]
end

function BinaryHeap:valueBynode(node)
	return self.values[self.reverse[node]]
end

function BinaryHeap:remove(pos)
	local last = #self.values
	if pos < 1 then
		return
	end
	if pos < last then
		local v = self.values[pos]
		self:swap(pos, last)
		self:erase(last)
		self:bubbleUp(pos)
		self:sinkDown(pos)
		return v
	end
	if pos == last then
		local v = self.values[pos]
		self:erase(last)
		return v
	end
end

function BinaryHeap:pop()
	if self.values[1] then
		local node = self.nodes[1]
		local value = self:remove(1)
		return node, value
	end
end

function BinaryHeap:size()
	return #self.values
end

function BinaryHeap:removeNode(node)
	local pos = self.reverse[node]
	if pos ~= nil then
		return self:remove(pos), node
	end
end

function BinaryHeap:insert(value, node)
	assert(self.reverse[node] == nil, "node already exists")
	assert(value ~= nil, "inserted value is nil")
	
	local pos = #self.values + 1
	self.reverse[node] = pos
	self.nodes[pos] = node
	
	self.values[pos] = value
	self:bubbleUp(pos)
end

function BinaryHeap:update(node, newValue)
	local pos = self.reverse[node]
	assert(pos >= 1 and pos <= #self.values, "position is invalid")
	assert(newValue ~= nil, "inserted value is nil")
	self.values[pos] = newValue
	if pos > 1 then
		self:bubbleUp(pos)
	end
	if pos < #self.values then
		self:sinkDown(pos)
	end
end

return BinaryHeap
