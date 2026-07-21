local M = {}

function M.evaluate_line(ctx)
	return {
		success = true,
		output = "=> fake result",
	}
end

function M.evaluate_selection(ctx)
	return {
		success = true,
		output = "=> fake selection result",
	}
end

function M.evaluate_buffer(ctx)
	return {
		success = true,
		output = "=> fake buffer result",
	}
end

return M
