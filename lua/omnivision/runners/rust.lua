local M = {}

local uv = vim.loop

local function temp_name(ext)
	local tmp = vim.fn.tempname()
	return tmp .. ext
end

function M.evaluate(code)
	local source = temp_name(".rs")
	local binary = temp_name("")

	local wrapped = string.format(
		[[
fn main() {
	println!("{:?}", %s);
}
]],
		code
	)

	local file = io.open(source, "w")

	if not file then
		return {
			success = false,
			output = "failed to create temp file",
		}
	end

	file:write(wrapped)
	file:close()

	local compile = vim.fn.system({
		"rustc",
		source,
		"-o",
		binary,
	})

	if vim.v.shell_error ~= 0 then
		return {
			success = false,
			output = compile,
		}
	end

	local output = vim.fn.system(binary)

	if vim.v.shell_error ~= 0 then
		return {
			success = false,
			output = output,
		}
	end

	return {
		success = true,
		output = "=> " .. vim.trim(output),
	}
end

return M
