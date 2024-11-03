local conf = require("telescope.config").values
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")

local module = require("elixir_dev.module")

local M = {}

function M.find_describes(opts)
	opts = opts or {}

	local bufnr = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(bufnr)

	pickers
		.new(opts, {
			prompt_title = "Public Functions",
			finder = finders.new_table({
				results = module.get_module_public_function_nodes() or {},
				entry_maker = function(entry)
					local formated = module.format_node_function(entry, bufnr)
					local lnum = entry:start()

					return {
						value = formated,
						display = formated,
						ordinal = formated,
						path = path,
						filename = path,
						lnum = lnum + 1,
					}
				end,
			}),
			previewer = require("telescope.config").values.grep_previewer({}),
			sorter = conf.generic_sorter(opts),
		})
		:find()
end

return M
