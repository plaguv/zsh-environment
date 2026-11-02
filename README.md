# Zsh Environment

A portable shell environment for my workstations. It uses [Zsh](https://www.zsh.org/) as the shell, [Starship](https://starship.rs/) for the prompt, and [mise](https://mise.jdx.dev/) to deploy dotfiles and manage language runtimes and command-line tools.

## Install

Simply clone the repository and run the installer:

```sh
git clone https://github.com/plaguv/zsh-environment.git \
  && cd zsh-environment
  && ./install.sh
```

The installer sets up base packages, applies the dotfiles from `dotfiles/`, and installs runtimes and command-line tools declared in the mise configuration. See the [installation guide](docs/INSTALLATION.md) for prerequisites and manual setup instructions.

## Neovim

The included Neovim configuration uses `lazy.nvim` to manage plugins and Mason to install language servers on first launch. It provides Blink LSP completion and navigation, Telescope file and text search, Tree-sitter highlighting, and the Nordic colorscheme. The package manifests install Neovim, ripgrep, and fd (`fdfind` on Debian).

The main Telescope shortcuts are `<Space>ff` to find files and `<Space>fg` to search file contents. Press `<C-Space>` to open completions; select items with `<Tab>`, `<C-n>` / `<C-p>`, or the arrow keys, then confirm with `<Enter>`. LSP buffers provide `gd` for definitions, `gr` for references, and `<Space>rn` to rename a symbol. Diagnostics appear in the sign column, inline, and in a bordered float; use `]d` and `[d` to move between them. Plugins and language servers are downloaded the first time Neovim starts, so that launch needs network access.

## Terminal preview

![Terminal preview of the Zsh environment](docs/banner.png)
