# Zsh Environment

A portable shell environment for my workstations. It uses [Zsh](https://www.zsh.org/) as the shell, [Starship](https://starship.rs/) for the prompt, and [mise](https://mise.jdx.dev/) to deploy dotfiles and manage language runtimes.

## Install

Simply clone the repository and run the installer:

```sh
git clone https://github.com/plaguv/zsh-environment.git \
  && cd zsh-environment
  && ./install.sh
```

The installer sets up packages, applies the dotfiles from `dotfiles/`, and installs the runtimes declared in the mise configuration. See the [installation guide](docs/INSTALLATION.md) for prerequisites and manual setup instructions.

## Terminal preview

![Terminal preview of the Zsh environment](docs/banner.png)
