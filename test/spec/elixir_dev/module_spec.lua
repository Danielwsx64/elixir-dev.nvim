local module = require("elixir_dev.module")

describe("_get_module_name", function()
	it("return module name", function()
		local text = {
			"defmodule Example.Module do",
			"  def function_name(arg) do",
			"    :ok",
			"  end",
			"",
			"  def function_name do",
			"  end",
			"end",
		}

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local node = root:child(0):child(2):child(1):child(2):child(1)

		assert.are.equal("Example.Module", module._get_module_name(buf, node))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when buffer does not have a defmodule", function()
		local text = {
			"  def function_name(arg) do",
			"    :ok",
			"  end",
			"",
			"  def function_name do",
			"  end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(bufnr, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local node = root:child(0):child(2):child(1)

		assert.are.equal("Example.Module", module._get_module_name(bufnr, node))

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)
