FROM debian:bookworm-slim

# 基本ツール
RUN apt-get update && apt-get install -y \
    zsh curl git tmux python3 python3-pip jq xz-utils ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# zsh をデフォルトシェルに
SHELL ["/bin/zsh", "-c"]

# ---------------------------------------------------------
# Install latest Neovim (from GitHub Releases)
# ---------------------------------------------------------
RUN NVIM_URL=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
      | jq -r '.assets[] | select(.name | test("nvim-linux-x86_64\\.tar\\.gz$")) | .browser_download_url') \
    && curl -L "$NVIM_URL" -o /tmp/nvim.tar.gz \
    && mkdir -p /opt/nvim \
    && tar -xzf /tmp/nvim.tar.gz -C /opt/nvim --strip-components=1 \
    && ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim \
    && rm -f /tmp/nvim.tar.gz

# ---------------------------------------------------------
# Node.js(pyright 用)
# ---------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# pyright(LSP)
RUN npm install -g pyright

# ---------------------------------------------------------
# lua-language-server(ソースからビルド)
# ---------------------------------------------------------
# ビルド依存関係をインストール
RUN apt-get update && apt-get install -y \
    ninja-build g++ libstdc++-12-dev \
    libunwind-dev binutils-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ソースからビルド
RUN git clone --depth=1 https://github.com/LuaLS/lua-language-server /tmp/lua-language-server \
    && cd /tmp/lua-language-server \
    && bash make.sh \
    && mkdir -p /opt/lua-language-server \
    && cp -r bin /opt/lua-language-server/ \
    && cp -r main.lua /opt/lua-language-server/ \
    && cp -r debugger.lua /opt/lua-language-server/ \
    && cp -r locale /opt/lua-language-server/ \
    && cp -r meta /opt/lua-language-server/ \
    && cp -r script /opt/lua-language-server/ \
    && ln -s /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server \
    && cd / \
    && rm -rf /tmp/lua-language-server

# ---------------------------------------------------------
# Install starship
# ---------------------------------------------------------
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# ---------------------------------------------------------
# Git safe.directory 設定（すべてのリポジトリを許可）
# ---------------------------------------------------------
RUN git config --global --add safe.directory '*'

# ---------------------------------------------------------
# dotfiles のコピーとインストール
# ---------------------------------------------------------
COPY . /root/.dotfiles
RUN cd /root/.dotfiles && ./install

# ---------------------------------------------------------
# Neovim 初回起動（mini.nvim プラグインセットのインストール）
# ---------------------------------------------------------
RUN nvim --headless "+lua \
      if pcall(require, 'mini.deps') then \
        require('mini.deps').update() \
      end" +qa
