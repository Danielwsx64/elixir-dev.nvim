local string_utils = require("elixir_dev.utils.string")

describe("indent_to", function()
	it("split string by new lines and add spaces to begining of each line", function()
		local text = "var = value\n|> function()\n|> another_fn()"

		local expected = { "var = value", "  |> function()", "  |> another_fn()" }

		assert.combinators.match(expected, string_utils.indent_to(text, 2))
	end)
end)
