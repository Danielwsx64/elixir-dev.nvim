local switch_keys = require("elixir_dev.switch_keys")

describe("_to_atoms", function()
	it("simple map", function()
		local text = { '%{"key" => value}' }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		switch_keys._to_atoms(node, buf)

		local result = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

		local expected = "%{key: value}"

		assert.are.equal(expected, result)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("multi keys", function()
		local text = { '%{"key" => value, "other" => value}' }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		switch_keys._to_atoms(node, buf)

		local result = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

		local expected = "%{key: value, other: value}"

		assert.are.equal(expected, result)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("multi keys with complex values", function()
		local text = { '%{"key" => {:v}, "other" => %{other: map}, "last" => [key: 3]}' }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		switch_keys._to_atoms(node, buf)

		local result = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

		local expected = "%{key: {:v}, other: %{other: map}, last: [key: 3]}"

		assert.are.equal(expected, result)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("multi keys with complex values and multi line", function()
		local text = {
			"%{",
			'  "key" => {:v},',
			'  "other" => %{other: map},',
			'  "last" => [key: 3]',
			"}",
		}
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		switch_keys._to_atoms(node, buf)

		local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

		local expected = {
			"%{",
			"  key: {:v},",
			"  other: %{other: map},",
			"  last: [key: 3]",
			"}",
		}

		assert.are.equal(table.concat(expected), table.concat(result))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)

describe("_to_strings", function()
	it("simple map", function()
		local text = { "%{key: value}" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		switch_keys._to_strings(node, buf)

		local result = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

		local expected = '%{"key" => value}'

		assert.are.equal(expected, result)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("multi keys", function()
		local text = { "%{key: value, other: value}" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		switch_keys._to_strings(node, buf)

		local result = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

		local expected = '%{"key" => value, "other" => value}'

		assert.are.equal(expected, result)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("multi keys with complex values", function()
		local text = { "%{key: {:v}, other: %{other: map}, last: [key: 3]}" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		switch_keys._to_strings(node, buf)

		local result = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")

		local expected = '%{"key" => {:v}, "other" => %{other: map}, "last" => [key: 3]}'

		assert.are.equal(expected, result)
		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("multi keys with complex values and multi line", function()
		local text = {
			"%{",
			"  key: {:v},",
			"  other: %{other: map},",
			"  last: [key: 3]",
			"}",
		}

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		switch_keys._to_strings(node, buf)

		local result = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

		local expected = {
			"%{",
			'  "key" => {:v},',
			'  "other" => %{other: map},',
			'  "last" => [key: 3]',
			"}",
		}

		assert.are.equal(table.concat(expected), table.concat(result))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)
