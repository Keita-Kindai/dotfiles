# dotfiles

Neovim（プラグインなしの最小構成）と WezTerm、競プロ用スクリプトの設定です。

## セットアップ（macOS / Ubuntu 共通）

```bash
git clone git@github.com:Keita-Kindai/dotfiles.git ~/dotfiles
sh ~/dotfiles/cp/install.sh
```

`install.sh` が行うこと:

- Ubuntu の場合は `g++ clangd python3 pipx xclip` を apt で入れる
- `oj` がなければ `pipx install online-judge-tools`
- `~/.config/nvim` を `dotfiles/nvim/nvim` へのリンクにする（既存の設定は退避）
- `cp-build` `cpt` `cpnew` を `~/.local/bin` にリンクする
- `~/CP` に `compile_flags.txt` と `.clangd` を置く（clangd 用）
- `~/CP/atcoder` も `~/CP/ac-library` もなければ ACL を clone する

Neovim は 0.11 以上が必要です（`vim.lsp.config` を使っています）。Ubuntu の apt 版は古いことが多いので、公式の AppImage か tarball を使ってください。

## 競プロの流れ

```bash
cpnew https://atcoder.jp/contests/abc400   # URL をそのまま貼る（abc400 だけでも可）
cpnew https://atcoder.jp/contests/adt_all_20251106_1   # ADT も同じ
cpnew abc400 a b      # 問題を指定する場合
cd ~/CP/contests/abc400/a
nvim main.cpp
```

Neovim 内のキー:

| キー | 動作 |
| --- | --- |
| `F5` | ビルドしてサンプル（`test/`）で `oj t` |
| `F6` | ビルドして手入力で実行 |
| `F8` | テストして提出（`cps`） |
| `:P b` | 同じコンテストの b 問題に切り替え（保存してから移動、Tab 補完あり） |
| `Space n` / `Space p` | 次 / 前の問題へ |
| `:Lib seg` | icpc-kit の自作ライブラリを `int main()` の直前に挿入（Tab 補完あり） |
| `:%y` | ファイル全体をクリップボードへコピー（提出用） |
| `Ctrl-Space` | 補完を手動で開く（`.` `->` `::` の後は自動） |
| `Tab` / `Shift-Tab` | 補完候補の選択、`Ctrl-y` で確定 |

シェルからは `cpt` でビルドとサンプルテスト、`cpt -e 1e-6` で誤差ジャッジです。

## 提出

1. 最初に 1 回（と cookie の期限切れ時）: 普段のブラウザで AtCoder にログインし、開発者ツールの Application → Cookies → `atcoder.jp` から `REVEL_SESSION` の値をコピーして `atcoder-login` に貼る（`oj login` は Cloudflare で止まるので使わない）
2. 問題フォルダで `cps` を実行する。サンプルが全部通ったら `oj s` で C++23 (GCC 15.2.0)（ID 6017）として提出する。言語を変えるときは `CP_LANG=6116 cps` のように指定する
3. コンテスト外は提出フォームに CAPTCHA があり `oj s` が失敗する。そのときは `main.cpp` をクリップボードにコピーして問題ページを開くので、手で貼って提出する

## oj のパッチ

AtCoder のメモリ制限表記が `MB` から `MiB` に変わり、oj が `assert parsed_memory_limit` で落ちます。
`cp/patch-oj.py` が oj 本体を修正します（`install.sh` から自動で実行。oj を入れ直したら再実行）。

## ライブラリの扱い

- ACL: `#include <atcoder/all>` のまま書く。AtCoder はそのまま提出できる。他サイトでは icpc-kit の `ace` か `oj-bundle` で展開してから提出する。
- 自作ライブラリ: `icpc-kit/my-library` に置き、`:Lib 名前` で貼り付ける。新しく足すときは `icpc-kit/scripts/library_insert/library_insert.py` の `LIBRARIES` に名前を登録する。
