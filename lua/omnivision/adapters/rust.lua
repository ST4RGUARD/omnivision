local M = {}

function M.evaluate(ctx)
	local observations = {}

	if ctx.mode == "line" then
		table.insert(observations, {
			line = ctx.cursor_line,
			output = "=> rust line evaluation",
		})
	end

	if ctx.mode == "selection" then
		table.insert(observations, {
			line = ctx.end_line,
			output = "=> rust selection evaluation",
		})
	end

	if ctx.mode == "buffer" then
		for line = ctx.start_line, ctx.end_line do
			table.insert(observations, {
				line = line,
				output = "=> rust line " .. line,
			})
		end
	end

	return {
		success = true,
		observations = observations,
	}
end

return M
