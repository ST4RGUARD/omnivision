local M = {}

local next_id = 0

local pending = {}

local latest_by_buffer = {}

function M.create(bufnr, callback)
	next_id = next_id + 1

	local id = next_id

	pending[id] = {
		bufnr = bufnr,
		callback = callback,
	}

	latest_by_buffer[bufnr] = id

	return id
end

function M.resolve(id, response)
	local request = pending[id]

	if not request then
		return
	end

	pending[id] = nil

	local latest = latest_by_buffer[request.bufnr]

	if latest ~= id then
		return
	end

	if request.callback then
		request.callback(response)
	end
end

function M.cancel_buffer(bufnr)
	latest_by_buffer[bufnr] = nil

	for id, request in pairs(pending) do
		if request.bufnr == bufnr then
			pending[id] = nil
		end
	end
end

function M.clear()
	pending = {}
	latest_by_buffer = {}
end

return M
