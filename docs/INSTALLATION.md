# Installation

This guide uses the GitHub repository [`plaguv/zsh-environment`](https://github.com/plaguv/zsh-environment).

## Automated setup

### Prerequisites

- `sudo` access.
- On macOS: Homebrew.

Clone the repository and run the installer from its directory:

```sh
  && ./install.sh
```

The installer detects the operating system and installs base packages from [`manifests/Brewfile`](../manifests/Brewfile) or [`manifests/apt-packages.txt`](../manifests/apt-packages.txt). It then trusts this repository's mise config, deploys the files under [`dotfiles/`](../dotfiles/) into your home directory, and runs `mise install` for the configured runtimes and command-line tools.

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

## Shared configuration and machine modules

`~/.config/mise/config.toml` contains the CLI tools shared by every machine and
is the place for shared `[settings]`, `[env]`, and `[tools]` values. Optional tool
groups are deployed alongside it as `config.<module>.toml`: `ai`, `go`, `java`,
`node`, `python`, `rust`, and `virtualization`. Their versions and environment
variables load together only when the module is selected.

`miserc.toml` selects all modules by default, preserving the previous setup.
Before running `mise install`, edit `~/.config/mise/miserc.toml` on each machine
to select just the modules it needs. For example, a Mac:

```toml
env = ["ai", "node", "python"]
```

A Debian workstation can instead select:

```toml
env = ["ai", "go", "java", "node", "python", "rust", "virtualization"]
```

`env = []` selects only the base config. The deployed `miserc.toml` is a copy:
reapplying dotfiles can overwrite destination edits or report a conflict. Edit
the repository copy too if you want the selection to persist across applies.
Use `~/.config/mise/config.local.toml` for machine-specific tool versions,
environment variables, or settings. For example:

```toml
[env]
EDITOR = "nvim"

[tools]
node = "24"
```

Local files override the shared configuration and selected modules. Keep these
files on the destination machine: repository `*.local.toml` files in the mise
source directory are ignored by Git and excluded from dotfile deployment, so
`mise dot apply` does not overwrite these local overrides. `miserc.toml` selects
environments; it does not accept `[tools]`, `[env]`, or `[settings]` tables.

Inspect the active files with `mise config`, or try a selection for one command
with `mise -E node,python config`. After changing the selection, run `mise install`.
Deselecting a module stops loading its tools and variables but does not uninstall
already downloaded tools.

When migrating an existing installation, remove the old deployed `conf.d/*.toml`
fragments for `ai`, `cli`, `go`, `java`, `node`, `python`, `rust`, and
`virtualization` after saving any machine-specific edits into `config.local.toml`.
Otherwise they continue enabling every tool regardless of the selected modules.
Review `mise dot diff` before applying.

See mise's [machine modules](https://mise.jdx.dev/bootstrap/modules.html) and
[configuration](https://mise.jdx.dev/configuration.html) documentation.

## Neovim configuration in the CLI module

Neovim is declared in `config.cli.toml`. Selecting `"cli"` in the `env` list
in `~/.config/mise/miserc.toml` enables both the CLI tools and deployment of
`dotfiles/.config/nvim/`. Run `mise dot apply` from this checkout, then
`mise install` to install the selected tools.

The main directory copy excludes `.config/nvim`; a separate copy entry with
`variants = [{ profile = "cli" }]` deploys it only when `cli` is selected.
The profile matches an environment name in `env`, not a tool or directory name.

Deselecting `cli` stops deploying the Neovim configuration and requesting the
CLI tools, but preserves previously deployed config and installed binaries.

## Preserve local Git settings

The Git config is excluded from the whole-directory copy and deployed through
an INI edit with `merge = "missing"`. `mise dot apply` fills in missing keys from
`dotfiles/.config/git/config` while retaining existing values, including
`user.name`, `user.email`, and machine-specific overrides. Subsequent changes
to repository defaults only affect keys that are still absent on the machine.
