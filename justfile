# ==========================================
# MASTER MAINTENANCE SCRIPT (BLUEFIN DX)
# ==========================================

# Execute all tasks (Update + Deep Clean)
all: update clean

# 1. System Updates (User-Space Only)
update:
    flatpak update -y
    /home/linuxbrew/.linuxbrew/bin/brew upgrade

# 2. Safe Cleanup (Reclaim Storage)
clean:
    flatpak uninstall --unused -y
    /home/linuxbrew/.linuxbrew/bin/brew cleanup --prune=all
    podman image prune -f

# 3. Sync Dotfiles (chezmoi hook)
sync:
    chezmoi update