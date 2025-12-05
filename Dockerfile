FROM debian:bookworm-slim

# 基本ツール
RUN apt-get update && apt-get install -y \
    zsh curl git python3 python3-pip jq xz-utils ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

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
# Node.js（pyright 用）
# ---------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_current.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# pyright（LSP）
RUN npm install -g pyright

# ---------------------------------------------------------
# lua-language-server（GitHub Releases）
# ---------------------------------------------------------
RUN LUA_URL=$(curl -s https://api.github.com/repos/LuaLS/lua-language-server/releases/latest \
      | jq -r '.assets[] | select(.name | test("linux-x64.*\\.tar\\.gz$")) | .browser_download_url') \
    && curl -L "$LUA_URL" -o /tmp/lua.tar.gz \
    && mkdir -p /opt/lua-language-server \
    && tar -xzf /tmp/lua.tar.gz -C /opt/lua-language-server --strip-components=1 \
    && ln -s /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server \
    && rm -f /tmp/lua.tar.gz

# ---------------------------------------------------------
# Install dotfiles
# ---------------------------------------------------------
COPY . /root/.dotfiles/.
RUN /root/.dotfiles/install

# ---------------------------------------------------------
# Install starship
# ---------------------------------------------------------
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# zsh をデフォルトシェルに
SHELL ["/bin/zsh", "-c"]

# starship を有効化する
RUN echo 'eval "$(starship init zsh)"' >> ~/.zshrc

# ---------------------------------------------------------
# Neovim 初回起動（mini.nvim プラグインセットのインストール）
# ---------------------------------------------------------
RUN nvim --headless "+lua \
      if pcall(require, 'mini.deps') then \
        require('mini.deps').update() \
      end" +qa

CMD ["zsh"]

