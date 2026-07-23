local M = {}

local job = nil
local queue = require("omnivision.core.queue")

local function runner_path()
	local source = debug.getinfo(1, "S").source

	source = source:sub(2)

	local plugin_root = source:match("(.+)/lua/omnivision/runners")

	return plugin_root .. "/lua/omnivision/runners/rust"
end

function M.start()
	if job then
		return
	end

	local runner = runner_path()

	vim.notify("Starting Rust runner: " .. runner)

	job = vim.fn.jobstart({
		"cargo",
		"run",
		"--quiet",
	}, {
		cwd = runner,

		stdout_buffered = false,

		on_stdout = function(_, data)
			if not data then
				return
			end

			for _, line in ipairs(data) do
				if line ~= "" then
					local ok, response = pcall(vim.json.decode, line)

					if not ok then
						vim.notify("Invalid runner response: " .. line, vim.log.levels.ERROR)

						goto continue
					end

					queue.resolve(response.id, response)

					::continue::
				end
			end
		end,

		on_stderr = function(_, data)
			if not data then
				return
			end

			for _, line in ipairs(data) do
				if line ~= "" then
					vim.notify("runner: " .. line, vim.log.levels.INFO)
				end
			end
		end,

		on_exit = function()
			job = nil
			queue.clear()
		end,
	})

	if job <= 0 then
		job = nil
		error("Failed to start OmniVision Rust runner")
	end

	vim.notify("OmniVision Rust runner started")
end

function M.stop()
	if job then
		vim.fn.jobstop(job)
		job = nil
	end

	queue.clear()
end

function M.send(payload, cb)
	if not job then
		error("Rust runner is not running")
	end

	local id = queue.create(payload.bufnr, cb)

	payload.id = id

	local json = vim.json.encode(payload)

	vim.notify("OmniVision request " .. payload.id, vim.log.levels.DEBUG)

	vim.fn.chansend(job, json .. "\n")
end

return M
