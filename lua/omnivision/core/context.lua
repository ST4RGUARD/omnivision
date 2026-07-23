local M = {}

function M.extract(ctx)
	return {
		code = ctx.code,
		context = nil,
	}
end

return M
