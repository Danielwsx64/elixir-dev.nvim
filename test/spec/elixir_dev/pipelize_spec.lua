local pipelize = require("elixir_dev.pipelize")

describe("_to_pipe", function()
	it("make a simple function a pipe", function()
		local text = { "function(argument)" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "argument\n|> function()"

		assert.are.equal(expected, pipelize._to_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when the function has more than one argument", function()
		local text = { "function(argument, %{key: 'value')" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "argument\n|> function(%{key: 'value')"

		assert.are.equal(expected, pipelize._to_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when the node has an assign argument", function()
		local text = { "result = ", "function(argument, %{key: 'value')" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "result = argument\n|> function(%{key: 'value')"

		assert.are.equal(expected, pipelize._to_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("a chain of fn calls with multiple args", function()
		local text = { "result = ", "third(second(first(argument, %{key: 'value'), {'tuple', 2}), ~D[2023-01-01])" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected =
			"result = argument\n|> first(%{key: 'value')\n|> second({'tuple', 2})\n|> third(~D[2023-01-01])"

		assert.are.equal(expected, pipelize._to_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("a call with a do block", function()
		local text = {
			"case value do",
			"{:ok, value} -> cool_function(value)",
			"{:error, _reason} = err -> err",
			"end",
		}
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "value\n|> case do\n{:ok, value} -> cool_function(value)\n{:error, _reason} = err -> err\nend"

		assert.are.equal(expected, pipelize._to_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when block has more than one arg and a block", function()
		local text = {
			"value =",
			"custom_function(%{}, ~D[2023-01-01]) do",
			"cool_function(value)",
			"end",
		}
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "value = %{}\n|> custom_function(~D[2023-01-01]) do\ncool_function(value)\nend"

		assert.are.equal(expected, pipelize._to_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)

describe("_undo_pipe", function()
	it("make a pipe a simple function call", function()
		local text = { "argument", "|> function()" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "function(argument)"

		assert.are.equal(expected, pipelize._undo_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when the function has more than one argument", function()
		local text = { "argument", "|> function(%{key: 'value'})" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "function(argument, %{key: 'value'})"

		assert.are.equal(expected, pipelize._undo_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when the node has an assign argument", function()
		local text = { "result =", "argument", "|> function(%{key: 'value'})" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "result = function(argument, %{key: 'value'})"

		assert.are.equal(expected, pipelize._undo_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("a chain of fn calls with multiple args", function()
		local text = {
			"result = argument",
			"|> first(%{key: 'value')",
			"|> second({'tuple', 2})",
			"|> third(~D[2023-01-01])",
		}
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "result = third(second(first(argument, %{key: 'value'), {'tuple', 2}), ~D[2023-01-01])"

		assert.are.equal(expected, pipelize._undo_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("a call with a do block", function()
		local text = {
			"value",
			"|> case do",
			"{:ok, value} -> cool_function(value)",
			"{:error, _reason} = err -> err",
			"end",
		}
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "case value do\n{:ok, value} -> cool_function(value)\n{:error, _reason} = err -> err\nend"

		assert.are.equal(expected, pipelize._undo_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when block has more than one arg and a block", function()
		local text = {
			"value =",
			"%{}",
			"|> custom_function(~D[2023-01-01]) do",
			"cool_function(value)",
			"end",
		}
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "value = custom_function(%{}, ~D[2023-01-01]) do\ncool_function(value)\nend"

		assert.are.equal(expected, pipelize._undo_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)

describe("_is_pipe", function()
	it("return true when the given node is a pipe operator", function()
		local text = { "result =", "value", "|> function()" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		assert.is_true(pipelize._is_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("return false when the given node is not a pipe operator", function()
		local text = { "result =", "value" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		assert.is_not_true(pipelize._is_pipe(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)
