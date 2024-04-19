local fn_shorthand = require("elixir_dev.fn_shorthand")

describe("_to_fn_shorthand", function()
	it("the most simple fn", function()
		local text = { "fn value -> value end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&(&1)"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("function with single arg and complex body", function()
		local text = { "fn value -> IO.inspect(value, limit: :infinity) end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&(IO.inspect(&1, limit: :infinity))"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("function with 2 arguments", function()
		local text = { "fn key, value -> IO.inspect({key, value}, limit: :infinity) end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&(IO.inspect({&1, &2}, limit: :infinity))"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when arguments apear more than once on body", function()
		local text = { "fn i, n, s -> IO.inspect(( i + n / s ) * i) end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&(IO.inspect((&1 + &2 / &3) * &1))"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("to shorthand arity sintax", function()
		local text = { "fn value -> IO.inspect(value) end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&IO.inspect/1"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("to shorthand arity sintax with two args", function()
		local text = { "fn key, value -> inspect(key, value) end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&inspect/2"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("to shorthand arity sintax with zero arguments", function()
		local text = { "fn -> IO.inspect() end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&IO.inspect/0"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when args are unordered dont use shorthand arity sintax", function()
		local text = { "fn key, value -> inspect(value, key) end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&(inspect(&2, &1))"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("ignore patter matching in arguments", function()
		local text = { "fn {i, n}, s -> IO.inspect(( i + n / s ) * i) end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "&(IO.inspect((i + n / &2) * i))"

		assert.are.equal(expected, fn_shorthand._to_fn_shorthand(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)

describe("_to_anonymous_fn", function()
	it("the most simple fn", function()
		local text = { "&(&1)" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "fn first -> first end"

		assert.are.equal(expected, fn_shorthand._to_anonymous_fn(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("function with single arg and complex body", function()
		local text = { "&(IO.inspect(&1, limit: :infinity))" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "fn first -> IO.inspect(first, limit: :infinity) end"

		assert.are.equal(expected, fn_shorthand._to_anonymous_fn(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("function with 2 arguments", function()
		local text = { "&(IO.inspect({&1, &2}, limit: :infinity))" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "fn first, second -> IO.inspect({first, second}, limit: :infinity) end"

		assert.are.equal(expected, fn_shorthand._to_anonymous_fn(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when arguments apear more than once on body", function()
		local text = { "&(IO.inspect((&1 + &2 / &3) * &1))" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "fn first, second, third -> IO.inspect((first + second / third) * first) end"

		assert.are.equal(expected, fn_shorthand._to_anonymous_fn(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("simple aritmetc operations", function()
		local text = { "&(&1 * &2)" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "fn first, second -> first * second end"

		assert.are.equal(expected, fn_shorthand._to_anonymous_fn(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("from shorthand arity sintax", function()
		local text = { "&IO.inspect/1" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "fn first -> IO.inspect(first) end"

		assert.are.equal(expected, fn_shorthand._to_anonymous_fn(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("from shorthand arity sintax with two args", function()
		local text = { "&inspect/2" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "fn first, second -> inspect(first, second) end"

		assert.are.equal(expected, fn_shorthand._to_anonymous_fn(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("from shorthand arity sintax with zero arguments", function()
		local text = { "&IO.inspect/0" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()
		local node = root:child(0)

		local expected = "fn  -> IO.inspect() end"

		assert.are.equal(expected, fn_shorthand._to_anonymous_fn(node, buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)
