-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 大文字の Q で現在のバッファ（ファイル）を閉じる
vim.keymap.set("n", "Q", "<leader>bd", { remap = true, desc = "Close Buffer (Safe)" })
