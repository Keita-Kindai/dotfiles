return {
    {
        "hrsh7th/nvim-cmp",
        opts = function(_, opts)
            local cmp = require("cmp")
            opts.mapping = vim.tbl_extend("force", opts.mapping, {
                -- 候補を明示的に選択していない時は、Enterキーを「確定」ではなく「通常の改行」にする
                ["<CR>"] = cmp.mapping.confirm({ select = false }),
            })
        end,
    }
}
