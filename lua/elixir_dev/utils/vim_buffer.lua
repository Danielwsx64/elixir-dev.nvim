local M = {}

function M.replace_content(buf, start_row, start_col, end_row, end_col, replacement, set_cursor)
	vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, replacement)

	if set_cursor == nil or set_cursor then
		vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
	end
end

return M
