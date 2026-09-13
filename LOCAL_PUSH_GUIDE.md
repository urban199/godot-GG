# Panduan push project game

Folder ini adalah salinan penuh repository game dan sudah memiliki workflow otomatis di `.github/workflows/`.

## Push pertama dari PowerShell

```powershell
cd "xnxx\game"
git config --local --add safe.directory "xnxx/game"
git status
git add .
git commit -m "Add local game assets"
git push origin main
```

Setelah push:

- `pages.yml` membangun preview Web dan deploy ke `https://urban199.github.io/game/`.
- `validate.yml` memeriksa struktur project.
- `android.yml` tersedia untuk export Android setelah SDK/signing dikonfigurasi.

## Upload asset

Letakkan model manual di `assets/characters/` atau `assets/environment/`. Format yang disarankan adalah `.glb` atau `.gltf`.

Jangan masukkan token, private key, atau file `.env` ke commit.
