local Self = {}

Self.replace_content = function(buf, start_row, start_col, end_row, end_col, replacement)
	vim.api.nvim_buf_set_text(buf, start_row, start_col, end_row, end_col, replacement)
	vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
end

return Self
