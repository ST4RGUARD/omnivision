local M = {}

local sessions = {}

function M.get(key)
	return sessions[key]
end

function M.create(key, session)
	sessions[key] = session
	return session
end

function M.remove(key)
	sessions[key] = nil
end

function M.clear()
	sessions = {}
end

return M
