# Private settings in `mise.local.toml`

These dotfiles hold no personal data. Values that identify you or your
machine, such as your git name, email, and signing key, live in an
untracked `mise.local.toml` at the root of your checkout. mise reads that
file during `mise bootstrap` and renders the values into the deployed
configs.

Without these values everything still installs, but git refuses to commit
until you set your name and email.

## Quick path

Run everything from the root of the checkout that `install.sh` ran from.

```sh
# 1. Start from the template, then fill in your values
#    (if mise.local.toml already exists, copy the [vars] block into it instead)
cp mise.local.toml.example mise.local.toml
$EDITOR mise.local.toml

# 2. Let mise load the new file
mise trust mise.local.toml

# 3. Render the git config with your values
mise dot apply ~/.config/git/config

# 4. Check: both print your values from ~/.config/git/config
git -C ~ config --show-origin --get user.name
git -C ~ config --show-origin --get user.email
```

`sh install.sh` also renders the values, because bootstrap applies every
template. Step 3 is just faster.

## Variables

| Variable | Needed | Renders into `~/.config/git/config` | Example |
| --- | --- | --- | --- |
| `git_name` | To commit | `user.name` | `"Your Name"` |
| `git_email` | To commit | `user.email` | `"you@example.com"` |
| `git_signingkey` | Optional | `user.signingkey`, and turns on `commit.gpgsign` | `"~/.ssh/id_ed25519.pub"` |
| `git_credential_url` | Optional | `[credential "<url>"]` with `helper = store` | `"https://git.example.com"` |

- **Signing key:** the config sets `gpg.format = ssh`, so the value must be an
  SSH public key, either a file path or `key::ssh-ed25519 AAAA...`. Leave it
  unset and commits are not signed.
- **Credential URL:** `helper = store` saves the credentials for that host in
  plain text in `~/.git-credentials`. Set it only if you accept that.
- **Any characters are safe.** Values are rendered quoted, with `\` and `"`
  escaped, so a `;`, `#`, apostrophe, or quote in a name stays intact.
- **Unset values** render nothing. They are declared with empty defaults
  under `[vars]` in `mise.toml`, and `mise.local.toml` overrides them.

`GITHUB_TOKEN` also lives in `mise.local.toml`, but only the test suite needs
it. See [github-token.md](github-token.md).

## What happens without them

| Missing | Effect |
| --- | --- |
| `git_name` or `git_email` | Bootstrap and `mise dot apply` print `NOTE: git user.name/user.email are not set, ...` pointing here. `git commit` fails with `fatal: no email was given and auto-detection is disabled`. The config sets `user.useConfigOnly = true`, so git never guesses an identity from your hostname. |
| `git_signingkey` | Commits are created but not signed. |
| `git_credential_url` | No credential helper; git uses its default prompt. |

## How it works

| File | Tracked | Role |
| --- | --- | --- |
| `.config/git/config.tera` | Yes | Template with shared settings and `{{ vars.* }}` placeholders |
| `mise.toml` `[vars]` | Yes | Public, empty defaults for every variable |
| `mise.local.toml.example` | Yes | Commented template to copy into `mise.local.toml` |
| `mise.local.toml` `[vars]` | No (git-ignored) | Your real values; they override the defaults |
| `~/.config/git/config` | No (generated) | Rendered output, overwritten on every apply |
| `~/.gitconfig` | No (machine-local) | Where `git config --global` writes; read after the rendered file, so it wins |

Every apply overwrites `~/.config/git/config`. To change shared settings,
edit `config.tera` and re-apply. Changes you make with `git config --global`
land in `~/.gitconfig` and persist.

`git config --global --list` shows only `~/.gitconfig` once that file
exists. Run `git -C ~ config --show-origin --list` to see both files, as git
itself reads them.

## Checklist

- [ ] `mise.local.toml` sits next to `mise.toml` and sets `git_name` and
      `git_email` under `[vars]`.
- [ ] `git status` does not list `mise.local.toml`.
- [ ] `git -C ~ config --show-origin --get user.email` prints your email from
      `~/.config/git/config`.
- [ ] `git commit` in any repository works without an identity error.

## Change or remove a value

- **Change:** edit `mise.local.toml`, then run `mise dot apply ~/.config/git/config`.
- **Remove:** delete the line, then re-apply. The rendered config drops it.
- **One identity for a single repository:** run
  `git config user.email <address>` inside it. Repository config wins over
  both global files.

## References

- mise templates: <https://mise.jdx.dev/dotfiles/managed.html>
- mise vars: <https://mise.jdx.dev/configuration/vars.html>
- git config files and precedence: <https://git-scm.com/docs/git-config#FILES>
- SSH commit signing: <https://git-scm.com/docs/git-config#Documentation/git-config.txt-gpgformat>
