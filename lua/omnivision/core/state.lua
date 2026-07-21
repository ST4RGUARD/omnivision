local M = {}

M.results = {}

function M.add(result)
	table.insert(M.results, result)
end

function M.last()
	return M.results[#M.results]
end

function M.remove_last()
	table.remove(M.results)
end

function M.get_buffer(bufnr)
	local results = {}

	for _, result in ipairs(M.results) do
		if result.bufnr == bufnr then
			table.insert(results, result)
		end
	end

	return results
end

function M.remove_buffer(bufnr)
	local remaining = {}

	for _, result in ipairs(M.results) do
		if result.bufnr ~= bufnr then
			table.insert(remaining, result)
		end
	end

	M.results = remaining
end

function M.clear()
	M.results = {}
end

return M
