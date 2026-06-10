local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _listeners = {} }, Signal)
end

function Signal:Connect(callback)
	local connection = { Connected = true, _callback = callback }
	table.insert(self._listeners, connection)
	return connection
end

function Signal:Fire(...)
	for _, conn in self._listeners do
		if conn.Connected then
			task.spawn(conn._callback, ...)
		end
	end
end

function Signal:Wait()
	local thread = coroutine.running()
	self:Connect(function(...)
		coroutine.resume(thread, ...)
	end)
	return coroutine.yield()
end

return Signal
