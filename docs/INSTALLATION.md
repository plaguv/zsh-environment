# Import Config

## Automated setup

Clone this repository, change into the checkout, and run:

```sh
./install.sh
```

The installer uses `manifests/Brewfile` on macOS or `manifests/apt-manifest.json` on Debian/Ubuntu to install the shell and bootstrap tools. It then applies dotfiles from this checkout with chezmoi and runs `mise install` for the runtimes declared in the mise config. Homebrew must already be installed on macOS; Debian/Ubuntu setup uses `sudo` when needed.

The repo's `.chezmoiroot` tells chezmoi to use `dotfiles/` as its source state, so there is no need to point chezmoi at that file directly.

## Manual chezmoi setup

chezmoi can clone this repository into its source directory and use it to set up your home directory. Replace `OWNER/REPOSITORY` below with this repository's URL or shorthand.

## Persistent setup

Initialize chezmoi from the repository, review the proposed changes, then apply them:

```sh
chezmoi init OWNER/REPOSITORY
chezmoi diff
chezmoi apply
```

To initialize and apply in one step:

```sh
chezmoi init --apply OWNER/REPOSITORY
```

This keeps the repository checkout and chezmoi configuration on the machine so you can update the dotfiles later with `chezmoi update`.

If the repository contains a `.chezmoi.toml.tmpl`, chezmoi uses it during `init` to generate the machine's local chezmoi configuration. That config is local to the machine and does not need to be managed as a home-directory dotfile.

## One-shot setup

For a temporary environment, chezmoi can apply the repository and then remove its checkout, configuration, cache, and binary:

```sh
chezmoi init --one-shot OWNER/REPOSITORY
```

Use this for disposable environments such as containers. Since chezmoi removes itself and its local state afterward, this is not suitable when you want to keep the checkout for future updates.
