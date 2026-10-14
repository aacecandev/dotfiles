FROM ubuntu:26.04

# Bare minimum so install.sh can run as a non-root user: sudo lets mise install
# the apt packages declared in [bootstrap.packages]. curl/ca-certificates and all
# other packages (git, zsh, unzip) are installed by install.sh / mise bootstrap.
RUN apt-get update \
    && apt-get install -y --no-install-recommends sudo \
    && rm -rf /var/lib/apt/lists/*

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

# Run install.sh on container start, then keep the container alive
# so you can `docker exec -it <container> zsh` into it.
CMD ["sh", "-c", "sh install.sh; exec sleep infinity"]
