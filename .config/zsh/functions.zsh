# Custom shell functions. Managed by mise dotfiles, deployed to
# $ZDOTDIR/functions.zsh and sourced from $ZDOTDIR/.zshrc.

################################################################
# Add your custom functions below
################################################################

#==========================================================
# Get a cheat sheet from cheat.sh
cheat() {
    curl cheat.sh/$1
}

#===============================================================
# Extract files
extract() {
    for file in "$@"
    do
        if [ -f $file ]; then
            _ex $file
        else
            echo "'$file' is not a valid file"
        fi
    done
}

# Extract files in their own directories
mkextract() {
    for file in "$@"
    do
        if [ -f $file ]; then
            local filename=${file%\.*}
            mkdir -p $filename
            cp $file $filename
            cd $filename
            _ex $file
            rm -f $file
            cd -
        else
            echo "'$1' is not a valid file"
        fi
    done
}

# Internal function to extract any archive
_ex() {
    case $1 in
        *.tar.bz2)  tar xjf $1      ;;
        *.tar.gz)   tar xzf $1      ;;
        *.bz2)      bunzip2 $1      ;;
        *.gz)       gunzip $1       ;;
        *.tar)      tar xf $1       ;;
        *.tbz2)     tar xjf $1      ;;
        *.tgz)      tar xzf $1      ;;
        *.zip)      unzip $1        ;;
        *.7z)       7z x $1         ;; # require p7zip
        *.rar)      7z x $1         ;; # require p7zip
        *.iso)      7z x $1         ;; # require p7zip
        *.Z)        uncompress $1   ;;
        *)          echo "'$1' cannot be extracted" ;;
    esac
}

#===============================================================
# Create a directory and cd into it
function mkcd() {
	mkdir -p "$@" && cd "$_";
}

#===============================================================
# https://docs.gitignore.io/install/command-line
function gi() {
  curl -sLw '\n' "https://www.toptal.com/developers/gitignore/api/${(j:,:)@}"
}

#===============================================================
# fix yubikey detection (restart pcscd + gpg-agent)
function fix-yubikey() {
    sudo systemctl restart pcscd
    gpgconf --kill gpg-agent
    gpgconf --launch gpg-agent
    sleep 1
    if ssh-add -L &>/dev/null ; then
        _success "YubiKey SSH key loaded"
        ssh-add -L
    else
        _error "YubiKey SSH key not found — check 'lsusb' and try a different port"
    fi
}

# Markdown editor
notes() {
    DOCKER_DEFAULT_PLATFORM=linux/amd64 docker run -it --rm --name notediscovery -p 8000:8000 -v $(pwd):/app/data ghcr.io/gamosoft/notediscovery:latest
}

# Excalidraw editor
excalidraw() {
    DOCKER_DEFAULT_PLATFORM=linux/amd64 docker run --rm -dit --name excalidraw -p 5000:80 excalidraw/excalidraw:latest
}

# Opencode
oc() {
    BASE_DIR="${HOME}/.config"

    #===============================================================

    export BLUE="\033[1;94m"
    export STRONG="\033[1;37m"
    export CYAN="\033[1;96m"
    export GREEN="\033[1;92m"
    export MAGENTA="\033[1;95m"
    export PURPLE="\033[1;35m"
    export RED="\033[1;31m"
    export YELLOW="\033[1;93m"
    export NC="\033[0m"

    function _info() {
        echo -e "${CYAN}==>  ${STRONG}${1}${NC}"
    }

    function _warning() {
        echo -e "${YELLOW}==>  ${1}${NC}"
    }

    function _success() {
        echo -e "${GREEN}==> ✔ ${NC}${1}"
    }

    function _error() {
        echo -e "${RED}==> ✘ ${MAGENTA}${1}${NC}\n"
    }

    #===============================================================

    export FZF_DEFAULT_OPTS="--pointer='▶' --style=full"

    OPENCODE_CONFIG="${BASE_DIR}/opencode"

    if [ -d "${OPENCODE_CONFIG}" ] && [ ! -L "${OPENCODE_CONFIG}" ]; then
        _error "${OPENCODE_CONFIG} must be a symlink!. bye"
        return 1
        elif [ -e "${OPENCODE_CONFIG}" ] && [ -L "${OPENCODE_CONFIG}" ]; then
        STATUS="✅"
    else
        STATUS="❌ BROKEN!"
    fi

    CURRENT_TARGET="$(basename "$(find "${BASE_DIR}" -maxdepth 1 -type l -name 'opencode' -exec readlink {} \;)")"

    NEW_TARGET="$(fd --base-directory "${BASE_DIR}" -t d -d 1 'opencode*' | sed 's|/$||' | fzf -e -i --prompt="${STATUS} Current ==> ${CURRENT_TARGET} > " --ghost="Switch to ..." --height=20% --layout=reverse --border --border-label="Opencode config switcher")"

    #===============================================================

    if [ ! -z "${NEW_TARGET}" ] && [ "${NEW_TARGET}" != "${CURRENT_TARGET}" ]; then
        (
            cd "${BASE_DIR}" || exit 1
            [[ "$(fd --base-directory "${BASE_DIR}" -t l -d 1 'opencode')" == "opencode" ]] &&
            [ -L opencode ] && unlink opencode
            _success "$(ln -vs "${NEW_TARGET}" opencode)"
        )
    else
        _info "No changes, using ${GREEN}${CURRENT_TARGET}\n"
    fi
}

# Opencode commit

# -- opencode commit
# Uses /commit command (required - https://gitlab.eu.intelygenz.com/devops/opencode/-/tree/main/commands)
# Respects env var DEFAULT_MODEL="<provider>/<preferred-model>", fallback to openai/gpt-5.3-codex
#
# Usage:  occ [--dry-run] [-f] <args>
#
# Examples
#   git add . && occ     (simple commits)
#   git add . && occ -f  (detailed commits)
occ() {
    local MODEL="${DEFAULT_MODEL:-openai/gpt-5.3-codex}"
    local AGENT=general COMMAND=commit THINKING=false DRY_RUN=false MODE=simple
    local DEFAULT_ARGS="and create scoped atomic commits"
    local OC_OVERRIDES="--dangerously-skip-permissions"

    usage() {
    cat <<EOF
Description:
    Run OpenCode commit command

Usage:
    ${FUNCNAME} [OPTIONS] [ARGS...]

Options:
    --dry-run       Show the command that would be executed without running it
    --full, -f      Use 'full' mode instead of 'simple' (more detailed commits)
    --help, -h      Show this help message
EOF
    }

    local -a POSITIONAL=()
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --dry-run)
                DRY_RUN=true
                shift
            ;;
            --full | -f)
                MODE=full
                shift
            ;;
            --help | -h)
                usage
                return 0
            ;;
            --)
                shift
                POSITIONAL+=("$@")
                break
            ;;
            -*)
                _error "Unknown option: ${1}"
                usage
                return 2
            ;;
            *)
                POSITIONAL+=("${1}")
                shift
            ;;
        esac
    done

    local -a CMD=(opencode run ${OC_OVERRIDES} --agent "${AGENT}" --model "${MODEL}" --thinking "${THINKING}" --command "${COMMAND}" "${MODE} ${POSITIONAL[*]} ${DEFAULT_ARGS}")

    if [[ "${DRY_RUN}" == "true" ]]; then
        echo "[DRY-RUN] ${CMD[*]}"
    else
        ga || return 1
        "${CMD[@]}"
        gl
    fi
}

# Claude commit
# Generate a Conventional Commit message for the staged diff with Claude
# (headless, sonnet) and commit it signed-off. Extra args are passed as hints.
claude-commit() {
  local diff msg
  diff="$(git diff --cached)" || return 1
  if [[ -z "$diff" ]]; then
    print -u2 "claude-commit: nothing staged"
    return 1
  fi
  msg="$(print -r -- "$diff" | claude -p --model sonnet --tools "" \
    "Write a Conventional Commit message for the staged git diff on stdin. \
Subject line max 72 chars, optional body wrapped at 72. \
Output ONLY the raw message: no code fences, no preamble, no AI attribution. $*")" || return 1
  [[ -z "$msg" ]] && { print -u2 "claude-commit: empty message"; return 1; }
  git commit -s -m "$msg"
}

# Atuin
atuin-clean-secrets() {
    local report="${TMPDIR}/atuin-secrets-report.json"

    echo "Scanning atuin history for secrets..."
    atuin search --cmd-only | gitleaks detect --pipe -r "$report" 2>&1

    local count
    count=$(jq 'length' "$report" 2>/dev/null || echo 0)

    if [[ "$count" -eq 0 ]]; then
        echo "No secrets found."
        rm -f "$report"
        return 0
    fi

    echo "Found $count leak(s). Deleting matching commands from atuin..."
    jq -r '.[].Match' "$report" | sort -u | while IFS= read -r cmd; do
        echo "  Deleting: ${cmd:0:60}..."
        atuin search --delete "$cmd"
    done

    shred --remove "$report"
    echo "Done. Run 'atuin sync' if using sync to propagate deletions."
}

# Silly little script to understand zstyle
names() {
    local user_name user_surname user_nickname computer_name

    zstyle -s ':name:' set_user_name user_name || user_name="LEELA"
    zstyle -s ':name:surname:' set_user_name user_surname || user_surname="TURANGA"
    zstyle -s ':name:nickname::' set_user_name user_nickname || user_nickname="CYCLOPE"
    zstyle -s ':name:' set_computer_name computer_name || computer_name="BENDER"

    echo "You're $user_name $user_surname $user_nickname and you're computer is called $computer_name"
}

zshcomp() {
    for command completion in ${(kv)_comps:#-*(-|-,*)}
    do
        printf "%-32s %s\n" $command $completion
    done | sort
}
