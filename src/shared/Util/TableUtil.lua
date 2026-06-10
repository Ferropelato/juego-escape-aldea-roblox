local TableUtil = {}

function TableUtil.deepCopy(original)
	local copy = {}
	for key, value in original do
		if type(value) == "table" then
			copy[key] = TableUtil.deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

function TableUtil.merge(into, from)
	for key, value in from do
		into[key] = value
	end
	return into
end

function TableUtil.keys(tbl)
	local result = {}
	for key in tbl do
		table.insert(result, key)
	end
	return result
end

return TableUtil
