# ==========================================
# MASTER MAINTENANCE SCRIPT (BLUEFIN DX)
# ==========================================

# Execute all tasks (Update + Deep Clean)
all: update clean

# 1. System Updates
update:
    rpm-ostree upgrade
    flatpak update -y
    brew upgrade
    fwupdmgr refresh || true
    fwupdmgr update -y || true

# 2. Safe Cleanup (Reclaim Storage)
clean:
    flatpak uninstall --unused -y
    brew cleanup --prune=all
    podman image prune -f

# 3. Sync Dotfiles (chezmoi hook)
sync:
    chezmoi update
