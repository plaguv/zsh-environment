# Installation

This guide uses the GitHub repository [`plaguv/zsh-environment`](https://github.com/plaguv/zsh-environment).

## Automated setup

### Prerequisites

- Git, to clone the repository.
- On macOS: Homebrew.
- On Debian or Ubuntu: Python 3 and `sudo` access. Run the installer as your normal user; it invokes `sudo` for apt commands when needed.

Clone the repository and run the installer from its directory:

```sh
git clone https://github.com/plaguv/zsh-environment.git
cd zsh-environment
./install.sh
```

The installer detects the operating system and installs packages from [`manifests/Brewfile`](../manifests/Brewfile) or [`manifests/apt-manifest.json`](../manifests/apt-manifest.json). It then applies the dotfiles from this checkout with chezmoi and runs `mise install` to install the runtimes declared in the mise configuration.

The installer does not change your login shell. Once setup finishes, start a Zsh session with `zsh` or set Zsh as your login shell using your operating system's usual method.

## Set up with chezmoi directly

If the required tools are already installed, chezmoi can clone the repository and apply the dotfiles. To preview changes first:

```sh
chezmoi init plaguv/zsh-environment
chezmoi diff
chezmoi apply
mise install
```

Or initialize and apply in one command:

```sh
chezmoi init --apply plaguv/zsh-environment
mise install
```

The repository's [`.chezmoiroot`](../.chezmoiroot) tells chezmoi that the source state is under `dotfiles/`. You do not need to point chezmoi at that file. This direct setup applies dotfiles and installs mise runtimes, but it does not install the system packages listed in `manifests/`.

## One-shot setup

For a disposable environment, chezmoi can apply the dotfiles and then remove its local source, configuration, cache, and binary:

```sh
chezmoi init --one-shot plaguv/zsh-environment
```

One-shot setup is intended for temporary environments such as containers. It does not run `install.sh` or install the runtimes declared by mise.
