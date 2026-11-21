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

The installer detects the operating system and installs base packages from [`manifests/Brewfile`](../manifests/Brewfile) or [`manifests/apt-packages.txt`](../manifests/apt-packages.txt). It then trusts this repository's mise config, deploys the files under [`dotfiles/`](../dotfiles/) into your home directory, and runs `mise bootstrap --only packages,services,tools` for the selected modules.

Before deploying dotfiles, the installer calls `dotfiles/.local/bin/refresh-ssh-keys.sh`. You can also run `refresh-ssh-keys.sh` after deployment. It creates two independent Ed25519 key pairs: `~/.ssh/id_ed25519` (authentication) and `~/.ssh/id_ed25519_signing` (signing), each with a corresponding `.pub` file. Both private keys are loaded into an SSH agent. When replacing a pair, the script removes its old identity from the selected agent before overwriting key files; unrelated identities remain loaded. New keys prompt for a passphrase. Each existing pair gets its own overwrite prompt, defaulting to no. Declining preserves the pair and restores a missing public file; mismatched or orphaned public keys stop setup. Both pairs are prepared and checked before existing files are changed. Register each public key with your Git hosting service for its respective purpose.

To migrate from the previous shared-key setup, decline replacement of `id_ed25519` and approve replacement of `id_ed25519_signing`. This preserves your authentication key and replaces the old signing public file with a new independent signing pair. Register the new signing public key with your Git hosting service. Git's `user.signingKey` should point to `~/.ssh/id_ed25519_signing.pub`.

The script reuses a reachable agent or starts one at `~/.ssh/agent.sock`. New Zsh sessions pick up that socket when no agent is already configured. A child script cannot change its parent shell's environment: when it selects this socket, it prints an `export SSH_AUTH_SOCK=...` command to run in your current terminal. After a reboot, rerun the script to start the agent and unlock the key again.

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
`cli`, `node`, `python`, `rust`, `podman`, and `kubernetes`. Their versions and environment
variables load together only when the module is selected.

`miserc.toml` selects `ai` and `cli` by default.
Before running `mise install`, edit `~/.config/mise/miserc.toml` on each machine
to select just the modules it needs. For example, a Mac:

```toml
env = ["ai", "node", "python"]
```

A Debian workstation can instead select:

```toml
env = ["ai", "cli", "go", "java", "node", "python", "rust", "podman", "kubernetes"]
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

## Podman and Kubernetes modules

Replace `docker` or `virtualization` in your deployed `miserc.toml` with
`podman`, and select `kubernetes` separately if needed. The repository defaults
still enable only `ai` and `cli`. After preserving any local changes, remove
old deployed `~/.config/mise/config.docker.toml` and
`~/.config/mise/config.virtualization.toml`; directory copies may leave old
files behind. Remove the old Compose plugin launcher at
`~/.config/docker/cli-plugins/docker-compose` if it came from this repository.

The Podman module installs the full runtime through APT on Debian/Ubuntu or
Homebrew on macOS. mise manages `docker-compose` as the explicitly selected
provider for `podman compose`; Docker CLI, Docker Engine, Colima and a Docker
service declaration are no longer part of this module. Existing installations,
Docker services, images and containers are not removed or migrated automatically.

Podman already uses `$XDG_CONFIG_HOME/containers` for rootless configuration
and `$XDG_DATA_HOME/containers` for rootless persistent data. Its machine
configuration also follows XDG paths. On macOS, container storage is inside
the Linux VM. The module sets `REGISTRY_AUTH_FILE` to
`$XDG_CONFIG_HOME/containers/auth.json` so registry logins persist across
reboots. `DOCKER_CONFIG=$XDG_CONFIG_HOME/docker` keeps the external Compose
provider's configuration out of `~/.docker`. Runtime files stay in the
OS-managed runtime directory; do not redirect `XDG_RUNTIME_DIR` to persistent
storage. These user paths do not relocate rootful Podman storage.

After enabling the modules and deploying their configuration, run:

```sh
mise dot apply
mise bootstrap --only packages,services,tools --dry-run
mise bootstrap --only packages,services,tools
```

On macOS, initialize a machine once, then start it:

```sh
podman machine init
podman machine start
```

Linux runs containers directly. For the Compose provider to connect to the
rootless Podman API, enable its user socket on a systemd host:

```sh
systemctl --user enable --now podman.socket
```

### Docker API discovery (Testcontainers and k3d)

`config.podman.toml` is authoritative for the Docker-compatible endpoint:
its `[env]` values replace inherited Docker endpoint variables. No helper
script, alternate-runtime detection, or socket symlink is needed.

- **Linux:** `DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock` selects
  rootless Podman. If the runtime variable is missing, mise uses the standard
  `/run/user/<uid>` path. `.zshenv` exports this fallback only when the directory
  already exists and belongs to the current user. Neither creates a directory;
  the OS must provision the runtime directory and the user socket must be enabled.
- **macOS:** a mise template runs `podman machine inspect` to obtain the default
  machine's forwarded socket for `DOCKER_HOST`. Until Podman and its machine
  exist, this value is empty so initial bootstrap remains possible. Start the
  machine before running clients. Socket mount paths use `/var/run/docker.sock`
  inside the VM, not the forwarded socket on macOS.

`DOCKER_HOST` is the standard client discovery variable, not `DOCKER_SOCKET`.
`DOCKER_SOCK` supplies k3d's daemon-side socket mount path, and
`TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE` explicitly uses that same path for
Testcontainers' socket mounts. On Linux these are the rootless socket path
without `unix://`; on macOS both use the VM-side path.

These settings do not start the service or VM. Run clients from a mise-activated
shell or use `mise exec -- <command>`. GUI-launched IDEs need to inherit this
environment or have it configured explicitly.

For **rootless Podman**, the [Testcontainers Java guidance](https://java.testcontainers.org/supported_docker_environment/#podman)
requires disabling Ryuk. Set this only for the relevant project/test command,
for example in its `mise.local.toml`:

```toml
[env]
TESTCONTAINERS_RYUK_DISABLED = "true"
```

This is deliberately not a global default: disabling Ryuk removes its automatic
resource cleanup, so tests must clean up their containers and networks. Other
Testcontainers language implementations may have different requirements.

[k3d's Podman support](https://k3d.io/stable/usage/advanced/podman/) remains
experimental. Socket discovery alone does not satisfy rootless Kubernetes
requirements; cgroup v2/controller delegation and networking may need host/VM
configuration. These modules do not install k3d or configure that delegation.

For a local Unix socket, verify the Docker-compatible endpoint after starting
the socket service or machine:

```sh
printf 'DOCKER_HOST=%s\nDOCKER_SOCK=%s\n' "$DOCKER_HOST" "$DOCKER_SOCK"
curl --unix-socket "${DOCKER_HOST#unix://}" http://localhost/_ping
```

Rootless Linux also requires subordinate UID/GID mappings for your user in
`/etc/subuid` and `/etc/subgid`; check these if the host does not provision them
when creating users. Bootstrap installs packages but does not edit these mappings.

Use `podman info` and `podman compose version` to verify the setup. Commands
are named `podman` and `podman compose`; no Docker compatibility alias is added.

The Kubernetes module provides standalone `kubectl`, Helm, and the k3s binary
on Linux. It sets the XDG kubeconfig/kuberc paths and enables the `kubectlw`
alias. It does not create a cluster or install a k3s service. Provision a
cluster separately and place its kubeconfig at `$XDG_CONFIG_HOME/kube/config`.
macOS installs kubectl and Helm, skips the Linux-only k3s binary, and installs
Colima through Homebrew. Start its Linux VM and local k3s cluster with:

```sh
mkdir -p "$(dirname "$KUBECONFIG")"
colima start kubernetes --runtime containerd --kubernetes
kubectl cluster-info
```

Colima manages k3s inside that VM; mise's Linux k3s version does not pin the
VM's version. Add `--kubernetes-version` with a complete k3s release identifier
to select it explicitly. Colima's VM is separate from Podman's machine, so
images and containers are not automatically shared. The existing XDG variables
guide Colima's configuration and cache paths, although an existing `~/.colima`
directory takes precedence and Colima may still use `~/.kube` for temporary files.

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
