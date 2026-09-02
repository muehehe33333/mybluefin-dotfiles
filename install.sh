#!/bin/bash
# ==========================================
# BLUEFIN DX - AUTOMATED PROVISIONING SCRIPT
# ==========================================
set -e

echo "🚀 Starting Bluefin DX automated provisioning..."

echo "📦 Installing Flatpak packages..."
flatpak install flathub -y $(grep -v '^#' lists/flatpaks.txt)

echo "🍺 Installing Homebrew CLI tools..."
brew install $(cat lists/brew-leaves.txt)

echo "🛠️ Applying VS Codium Podman overrides..."
flatpak override --user --filesystem=xdg-run/podman com.vscodium.codium
flatpak override --user --env=DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock com.vscodium.codium
flatpak override --user --talk-name=org.freedesktop.Flatpak com.vscodium.codium

echo "🧠 Applying ZRAM and sysctl configuration..."
sudo mkdir -p /etc/systemd/zram-generator.conf.d/
sudo cp configs/zram/99-custom.conf /etc/systemd/zram-generator.conf.d/
sudo cp configs/zram/99-zram.conf /etc/sysctl.d/
sudo sysctl -p /etc/sysctl.d/99-zram.conf
sudo systemctl daemon-reload
sudo systemctl restart systemd-zram-setup@zram0.service

echo "🔐 Setting up scripts and Systemd timers..."
mkdir -p ~/.local/bin ~/.config/systemd/user
cp scripts/automated-backup.sh ~/.local/bin/automated-backup
chmod 700 ~/.local/bin/automated-backup

# Deploy Timers
cp configs/systemd/*.service ~/.config/systemd/user/
cp configs/systemd/*.timer ~/.config/systemd/user/

systemctl --user daemon-reload
systemctl --user enable --now restic-backup.timer
systemctl --user enable --now ml-sorter.timer

echo "✅ Provisioning complete! Insert credentials into ~/.local/bin/automated-backup"
