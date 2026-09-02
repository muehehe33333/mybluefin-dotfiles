# ==========================================
# MASTER MAINTENANCE SCRIPT (BLUEFIN DX)
# ==========================================

# Execute all tasks (Update + Deep Clean + Tidy)
all: update clean tidy

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

# 4. Micro-ML: Train the prediction model from dataset.csv
build-ml:
	@echo "🧠 Compiling Micro-ML sorting model..."
	uv run --with pandas --with scikit-learn train.py

# 5. Micro-ML: Execute background sorting inference
tidy:
	@echo "🧹 Running AI background sorter..."
	uv run --with pandas --with scikit-learn inference.py
