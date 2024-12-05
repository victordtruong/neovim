function ColorMyPencils(color)
	color = color or "tokyonight-night"
	vim.cmd.colorscheme(color)

end

return {
	 {
        "folke/tokyonight.nvim",
        lazy = false,
        opts = {},
        config = function()
            ColorMyPencils()
        end
    },
     {
        "rose-pine/neovim",
        name = "rose-pine",
        config = function()
            require('rose-pine').setup({
                disable_background = true,
                styles = {
                    italic = false,
                },
            })

            ColorMyPencils();
        end
    },
}
