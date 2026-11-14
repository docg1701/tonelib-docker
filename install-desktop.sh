#!/bin/bash

# Instala o ToneLib-GFX no menu de aplicativos.
# Gera entradas para o AppImage (se existir) e para o Docker.

set -e

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
INSTALL_DIR="$HOME/.local/share/applications"
ICON_PATH="$REPO_DIR/tonelib-icon.png"

echo "=== Instalando ToneLib-GFX no menu de aplicativos ==="

mkdir -p "$INSTALL_DIR"

# ---------------------------------------------------------------------------
# AppImage (preferido, se já foi gerado com ./build-appimage.sh)
# ---------------------------------------------------------------------------
APPIMAGE=$(ls -1 "$REPO_DIR"/ToneLib-GFX-*-x86_64.AppImage 2> /dev/null | head -1 || true)

if [ -n "$APPIMAGE" ]; then
    cat > "$INSTALL_DIR/tonelib-gfx-appimage.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ToneLib GFX
Comment=Amp and effects modeling software for guitar and bass
Exec="$APPIMAGE"
Path=$REPO_DIR
Icon=$ICON_PATH
Terminal=false
Categories=AudioVideo;Audio;
StartupNotify=true
StartupWMClass=ToneLib GFX
EOF
    chmod +x "$INSTALL_DIR/tonelib-gfx-appimage.desktop"
    echo "✅ Entrada do AppImage instalada: $(basename "$APPIMAGE")"
else
    echo "ℹ️  Nenhum AppImage encontrado (rode ./build-appimage.sh para gerar um)."
fi

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------
cat > "$INSTALL_DIR/tonelib-gfx-docker.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ToneLib GFX (Docker)
Comment=Amp and effects modeling software for guitar and bass
Exec=$REPO_DIR/run.sh
Path=$REPO_DIR
Icon=$ICON_PATH
Terminal=false
Categories=AudioVideo;Audio;
StartupNotify=true
StartupWMClass=ToneLib GFX
EOF
chmod +x "$INSTALL_DIR/tonelib-gfx-docker.desktop"
echo "✅ Entrada do Docker instalada: run.sh"

# Atualizar cache do menu
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$INSTALL_DIR"
fi

echo ""
echo "Os aplicativos aparecem no menu em: Menu → Som e Vídeo"
echo ""
echo "Para desinstalar:"
echo "  rm $INSTALL_DIR/tonelib-gfx-appimage.desktop $INSTALL_DIR/tonelib-gfx-docker.desktop"
