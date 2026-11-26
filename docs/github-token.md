# GitHub token for the test suite

`tests/run.sh` needs `GITHUB_TOKEN`. The bootstrap resolves every tool
through the GitHub API, and the anonymous rate limit (60 requests per hour)
runs out after a run or two, so `install` fails with `HTTP 403`.

Store the token encrypted with [age](https://age-encryption.org) in an
untracked `mise.local.toml`, and mise decrypts it whenever you run something
through mise in this checkout. CI needs none of this: the workflow passes
the automatic `secrets.GITHUB_TOKEN` to the test step.

## Quick path

Run everything from the repository root.

```sh
# 1. Generate an age identity (once per machine)
mkdir -p ~/.config/mise
mise exec age@1.2.1 -- age-keygen -o ~/.config/mise/age.txt

# 2. Enable mise's experimental age support for this checkout
printf '[settings]\nexperimental = true\n' >> mise.local.toml

# 3. Store the token encrypted (paste it at the hidden prompt)
mise set --age-encrypt --prompt --file mise.local.toml GITHUB_TOKEN

# 4. Run the tests; mise decrypts the token for the command
mise exec -- sh tests/run.sh
```

Before step 3, create the token as described in
[Create the token](#create-the-token).

The tests pass when `tests/run.sh` exits with `0` and `install.log` in the
newest `logs/` directory has no `HTTP 403`.

## Requirements

| Need | Why | Install |
| --- | --- | --- |
| mise | Encrypts and decrypts the value | Already installed by the bootstrap |
| `age-keygen` | Generates the identity, once | `mise exec age@1.2.1 -- age-keygen` (no global install) |
| A GitHub account | Issues the token | <https://github.com/settings/personal-access-tokens> |

You do **not** need sops. mise has age built in (`mise set --age-encrypt`).
The `age` binary is only used to generate the key.

## Create the token

1. Open <https://github.com/settings/personal-access-tokens/new>
   (fine-grained token).
2. Set an expiration date, for example 90 days.
3. Under **Repository access**, choose **Public repositories**.
4. Leave every permission at **No access**. A token without permissions is
   enough to raise the rate limit to 5,000 requests per hour.
5. Click **Generate token**, then copy it and paste it at the prompt in
   step 3 of the quick path. Do not save it anywhere else.

## Why `--file mise.local.toml`

Without `--file`, `mise set` writes to the nearest `mise.toml`, which is the
tracked bootstrap config at the repository root. That would:

- publish the ciphertext in a public repository (hard rule 1 in
  [AGENTS.md](../AGENTS.md#hard-rules)), and
- break the container bootstrap, because the container has no age identity
  and mise fails on values it cannot decrypt (`age.strict` defaults to
  `true`).

Do not use `--global` either: on a bootstrapped machine,
`~/.config/mise/config.toml` is a symlink to `.config/mise/config.toml` in
this repository.

`mise.local.toml` is git-ignored and the `Dockerfile` does not copy it, so
the secret stays on your machine. The same goes for the
`experimental = true` setting, which the shared config does not enable.

## How it works

| Step | What happens |
| --- | --- |
| `mise set --age-encrypt` | Writes `GITHUB_TOKEN = { age = "<base64>" }` under `[env]` in `mise.local.toml`. It encrypts to `~/.config/mise/age.txt`, plus `~/.ssh/id_ed25519` and `~/.ssh/id_rsa` when they exist. |
| `mise exec` / `mise run` / an activated shell | Decrypts the value with your identity and exports `GITHUB_TOKEN`. Task output shows it as `[redacted]`. |
| `tests/run.sh` | Forwards it by name (`docker run -e GITHUB_TOKEN`), so the value never shows up in commands or logs. |

## Checklist

- [ ] `~/.config/mise/age.txt` exists and is backed up somewhere safe; without
      it you cannot decrypt the token.
- [ ] `mise.local.toml` contains `experimental = true` and
      `GITHUB_TOKEN = { age = "..." }`.
- [ ] `git status` does not list `mise.local.toml`.
- [ ] `mise exec -- sh -c 'test -n "$GITHUB_TOKEN" && echo ok'` prints `ok`.

## Rotate or remove the token

- **Rotate:** create a new token and run step 3 again; it overwrites the value.
- **Remove:** delete the `GITHUB_TOKEN` line from `mise.local.toml` and revoke
  the token at <https://github.com/settings/personal-access-tokens>.

## References

- mise age secrets: <https://mise.jdx.dev/environments/secrets/age.html>
- GitHub fine-grained tokens: <https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens>
- GitHub API rate limits: <https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api>
