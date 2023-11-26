local highlighter = require("vim.treesitter.highlighter")

local Self = {}

Self.is_elixir_lang = function(buf)
	local buff_active = highlighter.active[buf]

	return buff_active and buff_active.tree._lang == "elixir" or false
end

Self.get_master_node = function(initial_node)
	local ts_utils = require("nvim-treesitter.ts_utils")

	local node = initial_node or ts_utils.get_node_at_cursor()

	local parent = node:parent()
	local start_row = node:start()

	while parent ~= nil and start_row == parent:start() and parent:type() ~= "body" do
		node = parent
		parent = node:parent()

		if parent and parent:type() == "binary_operator" then
			start_row = parent:start()
		end
	end

	return node
end

return Self
