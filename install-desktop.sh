#!/bin/bash

# Script para instalar o ToneLib-GFX no menu de aplicativos

set -e

DESKTOP_FILE="ToneLib-GFX-Docker.desktop"
INSTALL_DIR="$HOME/.local/share/applications"

echo "=== Instalando ToneLib-GFX no menu de aplicativos ==="

# Criar diretório se não existir
mkdir -p "$INSTALL_DIR"

# Copiar arquivo .desktop
cp "$DESKTOP_FILE" "$INSTALL_DIR/"

# Tornar executável
chmod +x "$INSTALL_DIR/$DESKTOP_FILE"

# Atualizar cache do menu
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$INSTALL_DIR"
fi

echo "✅ ToneLib-GFX instalado com sucesso!"
echo ""
echo "Você pode encontrar o aplicativo no menu:"
echo "  Menu → Som e Vídeo → ToneLib GFX (Docker)"
echo ""
echo "Para desinstalar, execute:"
echo "  rm $INSTALL_DIR/$DESKTOP_FILE"
