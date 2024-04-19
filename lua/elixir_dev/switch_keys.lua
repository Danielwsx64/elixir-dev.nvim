local vim_buffer = require("elixir_dev.utils.vim_buffer")
local treesitter_utils = require("elixir_dev.utils.treesitter")

local get_node_text = vim.treesitter.get_node_text

local Self = {}

Self._to_atoms = function(node, buf)
	-- This MUST by bode backward because the tree update will change the nodes positions
	for i = node:named_child(0):named_child_count() - 1, 0, -1 do
		local n = node:named_child(0):named_child(i)
		local key_node = n:named_child(0)
		local point_node = n:child(1)

		local start_row, start_col = key_node:range()
		local _, _, end_row, end_col = point_node:range()

		vim_buffer.replace_content(
			buf,
			start_row,
			start_col,
			end_row,
			end_col,
			{ get_node_text(key_node:named_child(0), buf) .. ":" },
			false
		)
	end
end

Self._to_strings = function(node, buf)
	-- This MUST by bode backward because the tree update will change the nodes positions
	for i = node:named_child(0):named_child(0):named_child_count() - 1, 0, -1 do
		local n = node:named_child(0):named_child(0):named_child(i)
		local key_node = n:named_child(0)

		local start_row, start_col, end_row, end_col = key_node:range()

		vim_buffer.replace_content(
			buf,
			start_row,
			start_col,
			end_row,
			end_col,
			{ string.format('"%s" => ', get_node_text(key_node, buf):gsub(": $", "")) },
			false
		)
	end
end

Self.call = function()
	local buf = treesitter_utils.get_current_elixir_buf()

	if not buf then
		return false
	end

	local node = treesitter_utils.get_parent_node({ "map" })

	if not node then
		return false
	end

	if node:named_child(0):named_child(0):type() == "keywords" then
		Self._to_strings(node, buf)
	else
		Self._to_atoms(node, buf)
	end
end

return Self
