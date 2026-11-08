#!/bin/sh
# Set up the competitive programming environment (macOS / Ubuntu).
# usage: sh ~/dotfiles/cp/install.sh
set -eu

dot="$(cd "$(dirname "$0")/.." && pwd)"
root=${CP_ROOT:-$HOME/CP}
bin="$HOME/.local/bin"
mkdir -p "$bin"
export PATH="$bin:$PATH"

# Packages (Ubuntu only; macOS uses Xcode clang + Homebrew).
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y g++ clangd git curl python3 pipx xclip wl-clipboard xdg-utils
    # clangd picks the newest GCC directory; its libstdc++ headers must exist,
    # or clangd reports "'bits/stdc++.h' file not found".
    gccver=$(ls /usr/lib/gcc/*-linux-gnu/ 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)
    [ -n "$gccver" ] && sudo apt-get install -y "libstdc++-$gccver-dev" || true

    # Neovim 0.11+ (apt's version is too old): official release in ~/.local/nvim.
    need_nvim=1
    if command -v nvim >/dev/null 2>&1; then
        minor=$(nvim --version | head -1 | sed -n 's/^NVIM v0\.\([0-9]*\).*/\1/p')
        [ -n "$minor" ] && [ "$minor" -ge 11 ] && need_nvim=0
    fi
    if [ "$need_nvim" = 1 ]; then
        case "$(uname -m)" in aarch64|arm64) arch=arm64 ;; *) arch=x86_64 ;; esac
        rm -rf "$HOME/.local/nvim"
        mkdir -p "$HOME/.local/nvim"
        curl -fL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$arch.tar.gz" \
            | tar xz -C "$HOME/.local/nvim" --strip-components=1
        ln -sf "$HOME/.local/nvim/bin/nvim" "$bin/nvim"
    fi
fi

# online-judge-tools, patched for AtCoder's "MiB" memory limit.
if ! command -v oj >/dev/null 2>&1; then
    pipx install online-judge-tools
    # oj imports distutils, removed in Python 3.12; setuptools provides it.
    pipx inject online-judge-tools setuptools
fi
oj_python=$(head -1 "$(command -v oj)" | sed 's/^#! *//')
"$oj_python" "$dot/cp/patch-oj.py"

# Neovim config
mkdir -p "$HOME/.config"
if [ -e "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
fi
ln -sfn "$dot/nvim/nvim" "$HOME/.config/nvim"

# Commands -> ~/.local/bin
for f in "$dot"/cp/bin/*; do
    ln -sf "$f" "$bin/$(basename "$f")"
done

# CP root: clangd config, AtCoder Library, icpc-kit (for :Lib)
mkdir -p "$root"
cp "$dot/cp/compile_flags.txt" "$dot/cp/.clangd" "$root/"
if [ ! -d "$root/atcoder" ] && [ ! -d "$root/ac-library" ]; then
    git clone --depth 1 https://github.com/atcoder/ac-library "$root/ac-library"
fi
if [ ! -d "$root/icpc-kit" ]; then
    git clone https://github.com/hamikan/icpc-kit "$root/icpc-kit" || echo "icpc-kit: clone failed (:Lib will not work)"
fi

echo
echo "done."
echo "If 'cpnew' is not found in a new terminal, log out and in again (or run: source ~/.profile)."
