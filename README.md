# dotfiles

## How To Install

- one-liner

```shell
git clone --recursive git@github.com:m02uku/.dotfiles.git ~/.dotfiles && cd ~/.dotfiles && docker compose build
```

# How To Update

```shell
cd ~/.dotfiles && git pull &&  docker compose build
```

## How To Use

```shell
make run {PROJEVT_DIR}
```

- if want to run in current directory:

```shell
make run $PWD
```

## Requirements

- Docker

## NOTE

- [x] tmux
- [ ] regrep
- [ ] Ctrl+z, fg
- [ ] fzf
- [ ] copilot_chat <space>cc, copilot_chat_open <space>co
- [ ] zoxide
