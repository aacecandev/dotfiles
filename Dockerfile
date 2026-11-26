FROM ubuntu:26.04@sha256:d66b366dac61b575bee2aef07e9c26e8070096fbe84a3d4d3eb0da069b5d76db

# Bare minimum so install.sh can run as a non-root user: sudo lets mise install
# the apt packages declared in [bootstrap.packages]. curl/ca-certificates and all
# other packages (git, zsh, unzip) are installed by install.sh / mise bootstrap.
# BuildKit cache mounts keep the apt downloads between builds; the image's
# docker-clean hook would delete them, so it is removed first.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update -qq \
    && apt-get install -y -qq --no-install-recommends sudo

# Non-root user with uid 1000 and zsh as login shell (zsh is installed later by
# mise bootstrap). Ubuntu 26.04 ships a default 'ubuntu' user at uid 1000; drop
# it first. Grant passwordless sudo so mise can run apt-get unattended.
RUN userdel -r ubuntu 2>/dev/null || true \
    && useradd -m -u 1000 -s /usr/bin/zsh test \
    && echo 'test ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/test \
    && chmod 0440 /etc/sudoers.d/test

USER test
WORKDIR /home/test/dotfiles
COPY --chown=test:test install.sh mise.toml ./
COPY --chown=test:test .config ./.config

# Put mise on PATH for interactive use once it's installed.
ENV PATH="/home/test/.local/bin:${PATH}"

# Run install.sh on container start, then drop into a login zsh. Start it with
# `docker run -it --rm`; leaving the shell (exit or Ctrl+D) stops and removes it.
CMD ["sh", "-c", "sh install.sh; exec zsh -l"]
