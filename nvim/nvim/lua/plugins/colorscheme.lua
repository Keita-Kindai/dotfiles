return {
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true, -- 背景透過
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      -- ステータスラインや特定グループの背景色も「NONE（透明）」に強制上書きする
      on_highlights = function(hl, c)
        hl.StatusLine = { bg = "NONE", fg = c.fg }        -- 中央のステータスライン帯
        hl.StatusLineNC = { bg = "NONE", fg = c.fg_dark } -- 非アクティブ時のステータスライン
        hl.MsgArea = { bg = "NONE" }                      -- 一番下のメッセージエリア
        hl.NormalNC = { bg = "NONE" }                     -- 非アクティブウィンドウの背景
        hl.TabLineFill = { bg = "NONE" }                  -- タブバー背景
      end,
    },
  },
}
