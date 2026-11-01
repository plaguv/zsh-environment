# Zsh Environment

A portable shell environment for my workstations. It uses [Zsh](https://www.zsh.org/) as the shell, [Starship](https://starship.rs/) for the prompt, [chezmoi](https://www.chezmoi.io/) to manage dotfiles, and [mise](https://mise.jdx.dev/) to manage language runtimes.

General shell utilities are installed through the system package manager: Homebrew on macOS or apt on Debian and Ubuntu.

## Install

Clone the repository and run the installer:

```sh
git clone https://github.com/plaguv/zsh-environment.git
cd zsh-environment
./install.sh
```

The installer sets up packages, applies the dotfiles, and installs the runtimes declared in the mise configuration. See the [installation guide](docs/INSTALLATION.md) for prerequisites and manual chezmoi options.

## Supported systems

The environment is mainly tested on macOS 27+ and Debian 13+. The installer also supports Ubuntu.

## Terminal preview

![Terminal preview of the Zsh environment](docs/banner.png)
