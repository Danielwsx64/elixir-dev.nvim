return require("telescope").register_extension({
	exports = {
		public_functions = require("elixir_dev.pickers.public_functions").find,
	},
})
