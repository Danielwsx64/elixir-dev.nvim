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

		assert.is_nil(module._get_module_name(bufnr, node))

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)

describe("get_module_public_function_nodes", function()
	it("return all module public functions nodes", function()
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

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(bufnr, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local expected_one = root:child(0):child(2):child(1)
		local expected_two = root:child(0):child(2):child(2)

		local node = root:child(0):child(2):child(1):child(2):child(1)

		local results = module.get_module_public_function_nodes(bufnr, node)

		assert.combinators.match(results[1], expected_one)
		assert.combinators.match(results[2], expected_two)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)

describe("format_node_function", function()
	it("return function name and arity for node", function()
		local text = {
			"defmodule Example.Module do",
			"  def function_name do",
			"  end",
			"",
			"  def function_name(arg) do",
			"  end",
			"",
			"  def function_name(arg, second) do",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(bufnr, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local fn_arity_zero = root:child(0):child(2):child(1)
		local fn_arity_one = root:child(0):child(2):child(2)
		local fn_arity_two = root:child(0):child(2):child(3)
		local row = fn_arity_two:start()

		print(vim.inspect(row))

		assert.are.equal("function_name/0", module.format_node_function(fn_arity_zero, bufnr))
		assert.are.equal("function_name/1", module.format_node_function(fn_arity_one, bufnr))
		assert.are.equal("function_name/2", module.format_node_function(fn_arity_two, bufnr))

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)
