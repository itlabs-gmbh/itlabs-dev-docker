# ─────────────────────────────────────────────────────────────────────────────
# itlabs Developer Container
# Base:        Ubuntu 24.04 LTS
# Includes:    nvm + Node.js LTS, git, Claude Code, Azure CLI, zsh + oh-my-zsh
# ─────────────────────────────────────────────────────────────────────────────
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Berlin

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    # Basics
    ca-certificates \
    curl \
    wget \
    gnupg \
    lsb-release \
    # Dev tools
    git \
    jq \
    unzip \
    zip \
    build-essential \
    # Shell
    zsh \
    # SSH / networking
    openssh-client \
    # Misc
    sudo \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# ── Azure CLI ─────────────────────────────────────────────────────────────────
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*

# ── Create non-root developer user ───────────────────────────────────────────
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

RUN userdel --remove ubuntu 2>/dev/null || true \
    && groupadd --force --gid "${USER_GID}" "${USERNAME}" \
    && useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/zsh "${USERNAME}" \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

# ── Setup script ────────────────────────────────────────────────────────────
COPY --chown=${USERNAME}:${USERNAME} setup.sh /usr/local/bin/itlabs-setup
RUN chmod +x /usr/local/bin/itlabs-setup

# ── Switch to dev user for user-scoped installs ───────────────────────────────
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# ── oh-my-zsh ─────────────────────────────────────────────────────────────────
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# ── nvm + Node.js LTS ─────────────────────────────────────────────────────────
# NVM_DIR must be a hardcoded path (ARG values are not interpolated in ENV)
ENV NVM_DIR=/home/dev/.nvm
ENV NODE_VERSION=lts/*

RUN mkdir -p "${NVM_DIR}" \
    && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    && . "${NVM_DIR}/nvm.sh" \
    && nvm install "${NODE_VERSION}" \
    && nvm alias default "${NODE_VERSION}" \
    && nvm use default \
    && nvm cache clear

# ── Claude Code & global bin symlinks ───────────────────────────────────────
RUN . "${NVM_DIR}/nvm.sh" \
    && npm install -g @anthropic-ai/claude-code

# Symlink node/npm/claude into /usr/local/bin + claude-itlabs wrapper (requires root)
USER root
RUN NODE_BIN="$(ls -d /home/dev/.nvm/versions/node/*/bin | tail -1)" \
    && ln -sf "${NODE_BIN}/node"   /usr/local/bin/node \
    && ln -sf "${NODE_BIN}/npm"    /usr/local/bin/npm \
    && ln -sf "${NODE_BIN}/npx"    /usr/local/bin/npx \
    && ln -sf "${NODE_BIN}/claude" /usr/local/bin/claude \
    && printf '#!/bin/sh\nexec claude --model qwen/qwen3.6-35b-a3b "$@"\n' \
    > /usr/local/bin/claude-itlabs \
    && chmod +x /usr/local/bin/claude-itlabs
USER dev

RUN echo '\n# nvm' >> /home/${USERNAME}/.zshrc \
    && echo 'alias claude-itlabs="claude --model qwen/qwen3.6-35b-a3b"' >> /home/${USERNAME}/.zshrc \
    && echo '\n# First-run setup' >> /home/${USERNAME}/.zshrc \
    && echo 'source /usr/local/bin/itlabs-setup' >> /home/${USERNAME}/.zshrc \
    && printf '# nvm (loaded for all shell modes)\nexport NVM_DIR="$HOME/.nvm"\n[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"\n[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"\n' \
    >> /home/${USERNAME}/.zshenv \
    && git config --global core.autocrlf input \
    && git config --global init.defaultBranch main \
    && mkdir -p /home/${USERNAME}/workspace
WORKDIR /home/${USERNAME}/workspace

# ── Inference server configuration (values injected via docker-compose / -e) ──
ENV ANTHROPIC_BASE_URL=""

# ── Entrypoint ────────────────────────────────────────────────────────────────
CMD ["/bin/zsh", "-i"]
