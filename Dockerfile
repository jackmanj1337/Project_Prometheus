# ============================================================
# Godot + Claude Code — Terminal Dev Container
# Base: Ubuntu 22.04 LTS
# ============================================================

FROM ubuntu:22.04

# ── Prevent interactive prompts during apt ──────────────────
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# ── Versions (update here to upgrade) ──────────────────────
ARG GODOT_VERSION=4.3
ARG NODE_MAJOR=20

# ── System dependencies ─────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Essentials
    curl wget git unzip ca-certificates gnupg \
    # Godot headless runtime deps
    libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 \
    libgl1-mesa-glx libglu1-mesa \
    # Build tooling (GDScript, C# etc.)
    build-essential \
    # Utilities
    bash-completion vim nano tree \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js (LTS) via NodeSource ────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] \
        https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# ── Claude Code CLI ─────────────────────────────────────────
RUN npm install -g @anthropic-ai/claude-code

# ── Godot headless binary ───────────────────────────────────
RUN wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
        -O /tmp/godot.zip && \
    unzip -q /tmp/godot.zip -d /tmp/godot_extracted && \
    mv /tmp/godot_extracted/Godot_v${GODOT_VERSION}-stable_linux.x86_64 /usr/local/bin/godot && \
    chmod +x /usr/local/bin/godot && \
    rm -rf /tmp/godot.zip /tmp/godot_extracted

# ── Godot export templates (needed for export commands) ─────
# Uncomment if you need to export your game from the container:
# RUN mkdir -p ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable && \
#     wget -q "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_export_templates.tpz" \
#         -O /tmp/templates.tpz && \
#     unzip -q /tmp/templates.tpz -d /tmp/templates && \
#     mv /tmp/templates/templates/* ~/.local/share/godot/export_templates/${GODOT_VERSION}.stable/ && \
#     rm -rf /tmp/templates.tpz /tmp/templates

# ── Create a non-root user ──────────────────────────────────
RUN useradd -ms /bin/bash developer
WORKDIR /workspace
RUN chown developer:developer /workspace

# ── Persist Claude Code auth across sessions ────────────────
RUN mkdir -p /home/developer/.claude && \
    chown -R developer:developer /home/developer/.claude

USER developer

# ── Shell quality-of-life ───────────────────────────────────
RUN echo 'alias godot="godot --headless"' >> ~/.bashrc && \
    echo 'alias ll="ls -lah --color=auto"' >> ~/.bashrc && \
    echo 'export PS1="\[\e[36m\][godot-claude]\[\e[0m\] \w \$ "' >> ~/.bashrc && \
    echo 'echo ""' >> ~/.bashrc && \
    echo 'echo "  🎮  Godot $(godot --version 2>/dev/null | head -1) — headless mode"' >> ~/.bashrc && \
    echo 'echo "  🤖  Claude Code $(claude --version 2>/dev/null)"' >> ~/.bashrc && \
    echo 'echo "  📁  Project mounted at /workspace"' >> ~/.bashrc && \
    echo 'echo ""' >> ~/.bashrc

CMD ["/bin/bash"]
