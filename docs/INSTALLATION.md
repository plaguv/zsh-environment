# Installation

This guide uses the GitHub repository [`plaguv/zsh-environment`](https://github.com/plaguv/zsh-environment).

## Automated setup

### Prerequisites

- Git, to clone the repository.
- On macOS: Homebrew.
- On Debian or Ubuntu: `sudo` access.

Clone the repository and run the installer from its directory:

```sh
git clone https://github.com/plaguv/zsh-environment.git \
  && cd zsh-environment
  && ./install.sh
```

The installer detects the operating system and installs packages from [`manifests/Brewfile`](../manifests/Brewfile) or [`manifests/apt-packages.txt`](../manifests/apt-packages.txt). It then trusts this repository's mise config, deploys the files under [`dotfiles/`](../dotfiles/) into your home directory, and runs `mise install` for the configured runtimes.

The contents of `dotfiles/` use the same names and directory layout as their destinations under your home directory. For example, `dotfiles/.config/zsh/aliases.zsh` is deployed as `~/.config/zsh/aliases.zsh`. mise uses copy mode, so edit the repository sources and rerun `mise dot apply` to deploy changes.

The installer does not change your login shell. Once setup finishes, start a Zsh session with `zsh` or set Zsh as your login shell using your operating system's usual method.

## Apply the configuration manually

If mise and the required packages are already installed, clone the repository and run:

```sh
git clone https://github.com/plaguv/zsh-environment.git
cd zsh-environment
mise trust mise.toml
mise dot diff
mise dot apply
mise install
```

This direct setup deploys the dotfiles and installs the runtimes, but it does not install the system packages listed in `manifests/`.
