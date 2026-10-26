-- Maid: collects connections / instances / callbacks and cleans them in one call.
local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(task)
	table.insert(self._tasks, task)
	return task
end

function Maid:Clean()
	local tasks = self._tasks
	for i = #tasks, 1, -1 do
		local t = tasks[i]
		tasks[i] = nil
		local kind = typeof(t)
		if kind == "RBXScriptConnection" then
			t:Disconnect()
		elseif kind == "Instance" then
			t:Destroy()
		elseif kind == "function" then
			task.spawn(t)
		elseif kind == "table" and type(t.Destroy) == "function" then
			t:Destroy()
		end
	end
end

Maid.Destroy = Maid.Clean

return Maid
