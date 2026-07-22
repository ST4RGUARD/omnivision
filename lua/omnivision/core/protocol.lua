local M = {}

function M.request(opts)
	return {
		language = opts.language,
		mode = opts.mode,

		code = opts.code or "",

		start_line = opts.start_line,
		end_line = opts.end_line,

		filetype = opts.filetype,
	}
end

function M.response(data)
	return {
		success = data.success or false,
		observations = data.observations or {},
		error = data.error,
	}
end

return M
