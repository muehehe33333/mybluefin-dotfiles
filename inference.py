import os
import fcntl
import shutil
import pandas as pd
import joblib
from pathlib import Path

DOWNLOADS_DIR = Path.home() / "Downloads"
REVIEW_DIR = DOWNLOADS_DIR / "_Review"
MODEL_PATH = Path(__file__).parent / "micro_sorter.joblib"

print("🚀 Initializing Micro-ML Inference Engine...")

# Ensure quarantine directory exists
REVIEW_DIR.mkdir(parents=True, exist_ok=True)

if not MODEL_PATH.exists():
    print("❌ Error: micro_sorter.joblib not found. Run train.py first.")
    exit(1)

pipeline = joblib.load(MODEL_PATH)

def is_file_locked(filepath):
    """Check if file is currently being downloaded or written to by another process."""
    try:
        with open(filepath, 'a') as f:
            fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
            fcntl.flock(f, fcntl.LOCK_UN)
        return False
    except BlockingIOError:
        return True
    except Exception:
        return True 

print(f"📂 Scanning {DOWNLOADS_DIR} for new files...")

files_to_process = [
    f for f in DOWNLOADS_DIR.iterdir() 
    if f.is_file() and not f.name.startswith('.')
]

if not files_to_process:
    print("🤷 No files found to process. Engine going back to sleep.")
    exit(0)

for filepath in files_to_process:
    if is_file_locked(filepath):
        print(f"🔒 Skipping locked file (likely downloading): {filepath.name}")
        continue

    filename = filepath.name
    extension = filepath.suffix.lower()
    size_bytes = filepath.stat().st_size

    # Prepare single-row feature matrix
    df_features = pd.DataFrame([{
        'filename': filename,
        'extension': extension,
        'size_bytes': size_bytes
    }])

    # Predict probability distribution
    probabilities = pipeline.predict_proba(df_features)[0]
    max_prob = max(probabilities)
    predicted_class_index = probabilities.argmax()
    predicted_dir = pipeline.classes_[predicted_class_index]

    # 90% Confidence Gate
    if max_prob >= 0.90:
        # Strip leading slash so it appends correctly to /home/user0/
        target_path = Path.home() / predicted_dir.strip("/")
    else:
        target_path = REVIEW_DIR
        print(f"⚠️ Low confidence ({max_prob:.2f}). Routing to quarantine.")

    target_path.mkdir(parents=True, exist_ok=True)
    destination = target_path / filename

    # Collision evasion: Auto-rename if file already exists in target
    if destination.exists():
        counter = 1
        while destination.exists():
            destination = target_path / f"{filepath.stem}_{counter}{extension}"
            counter += 1

    print(f"[{max_prob:.2f}] {filename} -> {target_path}")
    
    try:
        # shutil.move safely handles cross-device / BTRFS subvolume moves
        shutil.move(str(filepath), str(destination))
    except Exception as e:
        print(f"❌ Error moving {filename}: {e}")

print("✅ Inference pass complete.")