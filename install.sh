#!/bin/bash
# ==========================================
# BLUEFIN DX - AUTOMATED PROVISIONING SCRIPT
# ==========================================
set -e

echo "🚀 Starting Bluefin DX automated provisioning..."

# 1. Install Flatpak GUI Applications
echo "📦 Installing Flatpak packages..."
flatpak install flathub -y $(grep -v '^#' lists/flatpaks.txt)

# 2. Install Homebrew CLI Tools
echo "🍺 Installing Homebrew CLI tools..."
brew install $(cat lists/brew-leaves.txt)

# 3. Apply VS Codium Overrides for DevContainers
echo "🛠️ Applying VS Codium Podman overrides..."
flatpak override --user --filesystem=xdg-run/podman com.vscodium.codium
flatpak override --user --env=DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock com.vscodium.codium
flatpak override --user --talk-name=org.freedesktop.Flatpak com.vscodium.codium

# 4. Configure ZRAM and Kernel Settings
echo "🧠 Applying ZRAM and sysctl configuration..."
sudo mkdir -p /etc/systemd/zram-generator.conf.d/
sudo cp configs/zram/99-custom.conf /etc/systemd/zram-generator.conf.d/
sudo cp configs/zram/99-zram.conf /etc/sysctl.d/
sudo sysctl -p /etc/sysctl.d/99-zram.conf
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service

# 5. Deploy Backup Automation
echo "🔐 Setting up backup scripts and Systemd timers..."
mkdir -p ~/.local/bin ~/.config/systemd/user
cp scripts/automated-backup.sh ~/.local/bin/automated-backup
chmod 700 ~/.local/bin/automated-backup

cp configs/systemd/restic-backup.service ~/.config/systemd/user/
cp configs/systemd/restic-backup.timer ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable --now restic-backup.timer

echo "✅ Provisioning complete! Make sure to insert your real credentials into ~/.local/bin/automated-backup"
