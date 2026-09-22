"""Download Anima Aesthetic v1.1 diffusion model into ComfyUI models tree."""

from __future__ import annotations

import hashlib
import shutil
from pathlib import Path

from huggingface_hub import hf_hub_download

ROOT = Path(__file__).resolve().parents[1]
MODELS = ROOT / "models"

DOWNLOADS = (
    {
        "repo_id": "circlestone-labs/Anima",
        "filename": "split_files/diffusion_models/anima-aesthetic-v1.1.safetensors",
        "dest": MODELS / "diffusion_models" / "anima-aesthetic-v1.1.safetensors",
        "sha256": "3c1868387a3a1ff504bbb87c33678321965ead381fcf87afbd0264daa600c082",
    },
    {
        "repo_id": "circlestone-labs/Anima",
        "filename": "split_files/text_encoders/qwen_3_06b_base.safetensors",
        "dest": MODELS / "text_encoders" / "qwen_3_06b_base.safetensors",
        "sha256": "cd2a512003e2f9f3cd3c32a9c3573f820bb28c940f73c57b1ddaa983d9223eba",
    },
    {
        "repo_id": "circlestone-labs/Anima",
        "filename": "split_files/vae/qwen_image_vae.safetensors",
        "dest": MODELS / "vae" / "qwen_image_vae.safetensors",
        "sha256": "a70580f0213e67967ee9c95f05bb400e8fb08307e017a924bf3441223e023d1f",
    },
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(8 * 1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def copy_if_needed(src: Path, dest: Path, expected_sha256: str) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if dest.exists() and sha256(dest) == expected_sha256:
        print(f"already in place: {dest}")
        return
    shutil.copy2(src, dest)
    print(f"copied -> {dest}")


def main() -> None:
    for item in DOWNLOADS:
        dest = item["dest"]
        if dest.exists() and sha256(dest) == item["sha256"]:
            print(f"verified existing {dest.name}")
            continue
        print(f"downloading {item['repo_id']} / {item['filename']}")
        cached = Path(
            hf_hub_download(
                repo_id=item["repo_id"],
                filename=item["filename"],
            )
        )
        copy_if_needed(cached, dest, item["sha256"])
        actual = sha256(dest)
        if actual != item["sha256"]:
            raise RuntimeError(f"SHA-256 mismatch for {dest}: {actual}")
        print(f"done {dest.name} ({dest.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
