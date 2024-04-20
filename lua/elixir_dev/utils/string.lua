local M = {}

function M.indent_to(text, col)
	local lines = vim.split(text, "\n")

	for key, value in pairs(lines) do
		if key ~= 1 then
			lines[key] = string.rep(" ", col) .. string.match(value, "^%s*(.-)%s*$")
		end
	end

	return lines
end

return M
