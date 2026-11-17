# Private settings in `mise.local.toml`

These dotfiles hold no personal data. Values that identify you or your
machine, such as your git name, email, and signing key, live in an
untracked `mise.local.toml` at the root of your checkout. mise reads that
file during `mise bootstrap` and renders the values into the deployed
configs.

Create the file **before your first install** and everything is set up in
one run. Without it everything still installs, but git refuses to commit
until you set your name and email.

## Before you install

### What to prepare

| Item | Needed | Notes |
| --- | --- | --- |
| Name and email for commits | To commit | Your email is published in every commit you push. To keep it private, use GitHub's noreply address (`<id>+<username>@users.noreply.github.com`, see [commit email address](https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-personal-account-on-github/managing-email-preferences/setting-your-commit-email-address)). |
| SSH key for signing | Optional | An existing key works, or create one with `ssh-keygen -t ed25519`. See [Variables](#variables) for which path to use. |
| Host with stored credentials | Optional | Only if you want git to save that host's password in plain text. |
| GitHub token | Only for the test suite | See [github-token.md](github-token.md). Not needed to use the dotfiles. |

### Where everything lives

This guide clones to `~/dotfiles`. Any path works, but keep it: every
symlink points into the checkout, so moving it later breaks them.

| Path | What it is | Created by |
| --- | --- | --- |
| `~/dotfiles/` | The checkout | You (`git clone`) |
| `~/dotfiles/mise.local.toml` | Your private values (git-ignored) | You, from `mise.local.toml.example` |
| `~/.config/git/config` | Rendered git config, overwritten on every apply | mise |
| `~/.config/git/ignore` | Global gitignore (symlink into the checkout) | mise |
| `~/.gitconfig` | Machine-local git config; `git config --global` writes here | mise creates it with one comment line; you and your tools add to it |
| `~/.ssh/id_ed25519` and `.pub` | Optional signing key | You (`ssh-keygen`) |
| `~/.config/mise/age.txt` | Optional age identity that decrypts `GITHUB_TOKEN` | You, only for the tests |

## New machine: step by step

```sh
# 1. Clone to the path the dotfiles will live in
git clone https://github.com/aacecandev/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Create your private settings before installing
cp mise.local.toml.example mise.local.toml
$EDITOR mise.local.toml        # set git_name and git_email at least

# 3. Install. install.sh trusts every mise config in the checkout,
#    mise.local.toml included, and bootstrap renders your values
sh install.sh

# 4. Check: prints your email and file:~/.config/git/config
git -C ~ config --show-origin --get user.email
```

A filled-in `mise.local.toml` looks like this:

```toml
[vars]
git_name = "Ada Lovelace"
git_email = "12345+ada@users.noreply.github.com"
git_signingkey = "~/.ssh/id_ed25519.pub"   # key loaded in ssh-agent
```

If the install prints `NOTE: git user.name/user.email are not set`, the file
was missing or incomplete. Fix it and follow [Already installed](#already-installed).

### With `mise bootstrap --from`

`--from` clones the repository into mise's own cache, so you have no
checkout to put `mise.local.toml` in. If you want private settings, clone
the repository as shown above instead.

## Already installed

Run everything from the root of your checkout.

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

Running `sh install.sh` again also renders the values, because bootstrap
applies every template. Step 3 is just faster.

## Variables

| Variable | Needed | Renders into `~/.config/git/config` | Example |
| --- | --- | --- | --- |
| `git_name` | To commit | `user.name` | `"Your Name"` |
| `git_email` | To commit | `user.email` | `"you@example.com"` |
| `git_signingkey` | Optional | `user.signingkey`, and turns on `commit.gpgsign` | `"~/.ssh/id_ed25519.pub"` |
| `git_credential_url` | Optional | `[credential "<url>"]` with `helper = store` | `"https://git.example.com"` |

- **Signing key:** the config sets `gpg.format = ssh`. Use the public key
  path (`~/.ssh/id_ed25519.pub`) or a `key::ssh-ed25519 AAAA...` literal
  when the key is loaded in `ssh-agent`. Otherwise use the private key path
  (`~/.ssh/id_ed25519`). Leave it unset and commits are not signed. To show
  commits as verified on GitHub, also add the public key to your account as a
  [signing key](https://docs.github.com/en/authentication/managing-commit-signature-verification/about-commit-signature-verification).
- **Credential URL:** `helper = store` saves the credentials for that host in
  plain text in `~/.git-credentials`. Set it only if you accept that.
- **Special characters:** values are rendered quoted, with `\` and `"`
  escaped, so quotes, backslashes, apostrophes, `;`, and `#` stay intact.
  Newlines are not supported and break the rendered config.
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

## Keeping your copy

The repository never stores your `mise.local.toml`; it is yours. It is a few
lines long, so the simplest backup is a note in your password manager with
its contents. If you use the encrypted `GITHUB_TOKEN`, also keep
`~/.config/mise/age.txt` there, because nothing else can decrypt it. On a new
machine, paste the note or rebuild the file from `mise.local.toml.example`.

Never commit it. `.gitignore` already excludes it, and `git status` must not
list it.

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
