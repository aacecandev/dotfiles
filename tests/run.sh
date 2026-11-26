#!/usr/bin/env sh
# tests/run.sh — End-to-end test of the dotfiles in a disposable container.
#   1. Build the image with docker buildx (BuildKit cache, live progress).
#   2. Run tests/container.sh in one `docker run -it --rm` session: install.sh,
#      install.sh again (idempotence), then tests/checks.sh. All output
#      streams live to the terminal.
# Logs go to logs/<UTC timestamp>/; any failure is collected in errors.log.
# Usage:
#   sh tests/run.sh
set -u

root="$(cd "$(dirname "$0")/.." && pwd)"
# Unique tag per run so parallel runs never replace each other's image; the
# shared dotfiles-test tag is kept for manual inspection (AGENTS.md).
image="dotfiles-test:$$"
container="dotfiles-test-$$"
log_dir="$root/logs/$(date -u +%Y%m%dT%H%M%SZ)"
errors="$log_dir/errors.log"
mkdir -p "$log_dir"

cleanup() {
    docker rm -f "$container" >/dev/null 2>&1 || true
    docker image rm "$image" >/dev/null 2>&1 || true
}
# On Ctrl-C or kill, stop the run (exit fires the EXIT trap).
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

status=0
record() {
    printf '%s\n' "$1" >>"$errors"
    status=1
}

# Build, streaming output live and to build.log. The exit code goes through a
# file because a pipeline returns tee's status.
printf '==> build\n'
{
    docker buildx build --load --tag "$image" --tag dotfiles-test "$root"
    echo $? >"$log_dir/.build.rc"
} 2>&1 | tee "$log_dir/build.log"
rc="$(cat "$log_dir/.build.rc")"
rm -f "$log_dir/.build.rc"

if [ "$rc" -ne 0 ]; then
    record "[build] exited with $rc (see build.log)"
else
    # -t only with a terminal: under a git hook or CI stdin is not a TTY and
    # `docker run -t` would refuse to start.
    tty=-i
    if [ -t 0 ] && [ -t 1 ]; then tty=-it; fi
    # tests/ is mounted read-only so the image itself stays unchanged; the log
    # directory is mounted read-write so the container writes its step logs.
    # GITHUB_TOKEN is forwarded by name only so its value never hits argv.
    docker run "$tty" --rm --name "$container" \
        -e GITHUB_TOKEN \
        -e LOG_DIR=/home/test/logs \
        -v "$root/tests:/home/test/dotfiles/tests:ro" \
        -v "$log_dir:/home/test/logs" \
        "$image" sh tests/container.sh
    rc=$?
    if [ "$rc" -ne 0 ] && [ ! -s "$errors" ]; then
        record "[run] container exited with $rc"
    elif [ "$rc" -ne 0 ]; then
        status=1
    fi
fi

# mise can log errors and still exit 0; treat them as failures too.
for log in "$log_dir"/*.log; do
    [ "$log" = "$errors" ] && continue
    if grep -q 'mise ERROR' "$log" 2>/dev/null; then
        name="$(basename "$log" .log)"
        record "[$name] mise errors:"
        grep -n 'mise ERROR' "$log" >>"$errors"
    fi
done

if [ "$status" -eq 0 ]; then
    printf 'OK: all steps passed. Logs: %s\n' "$log_dir"
else
    printf 'FAILED: see %s\n' "$errors" >&2
    cat "$errors" >&2
fi
exit "$status"
