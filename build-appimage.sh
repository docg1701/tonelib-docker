#!/bin/bash

# Gera um AppImage standalone do ToneLib-GFX a partir do .deb oficial.
#
# O .deb NÃO é distribuído neste repositório (licença da ToneLib): baixe em
# https://tonelib.net/gfx-overview/ e salve como ToneLib-GFX-amd64.deb na raiz
# deste repositório antes de rodar o script.
#
# Uso: ./build-appimage.sh [--download]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
cd "$REPO_DIR"

DEB_FILE="ToneLib-GFX-amd64.deb"
DEB_URL="https://tonelib.net/download.php?id=gfx&os=lnx"

# Runtime do AppImage (type 2). Pinado por tag + sha256 para build reprodutível.
RUNTIME_TAG="20251108"
RUNTIME_URL="https://github.com/AppImage/type2-runtime/releases/download/${RUNTIME_TAG}/runtime-x86_64"
RUNTIME_SHA256="2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d"

CACHE_DIR="$REPO_DIR/.cache"
BUILD_DIR="$REPO_DIR/build"
APP_DIR="$BUILD_DIR/AppDir"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${YELLOW}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
die() { echo -e "${RED}[ERRO]${NC} $*" >&2; exit 1; }

DOWNLOAD=0
case "${1:-}" in
    --download) DOWNLOAD=1 ;;
    -h|--help)
        echo "Uso: ./build-appimage.sh [--download]"
        echo ""
        echo "  --download  baixa o .deb de tonelib.net se ele não estiver no diretório"
        echo ""
        echo "Gera ToneLib-GFX-<versão>-x86_64.AppImage."
        echo "Requer: curl, mksquashfs (pacote squashfs-tools) e dpkg (ou binutils/ar)."
        exit 0
        ;;
    "") ;;
    *) die "Argumento desconhecido: $1 (use --help)" ;;
esac

# ---------------------------------------------------------------------------
# Dependências do host
# ---------------------------------------------------------------------------
command -v mksquashfs > /dev/null 2>&1 || die "mksquashfs não encontrado.
  Debian/Ubuntu: sudo apt install squashfs-tools
  Fedora:        sudo dnf install squashfs-tools
  Arch:          sudo pacman -S squashfs-tools"

command -v curl > /dev/null 2>&1 || die "curl não encontrado."

# ---------------------------------------------------------------------------
# .deb de entrada
# ---------------------------------------------------------------------------
if [ ! -f "$DEB_FILE" ]; then
    if [ "$DOWNLOAD" -eq 1 ]; then
        info "Baixando o .deb de tonelib.net..."
        curl -fL --retry 3 -o "${DEB_FILE}.part" "$DEB_URL" || { rm -f "${DEB_FILE}.part"; die "Download falhou."; }
        [ "$(head -c 8 "${DEB_FILE}.part")" = '!<arch>' ] || { rm -f "${DEB_FILE}.part"; die "Download não é um .deb válido."; }
        mv "${DEB_FILE}.part" "$DEB_FILE"
    else
        die "$DEB_FILE não encontrado.
  Baixe em https://tonelib.net/gfx-overview/ (Ubuntu 64-bit) e salve como:
  $REPO_DIR/$DEB_FILE
  Ou rode: ./build-appimage.sh --download"
    fi
fi

# Lê um campo do control do .deb (dpkg-deb se existir, senão ar + tar)
deb_member() {  # $1 = prefixo do membro (control. / data.)
    ar t "$DEB_FILE" | grep -m1 "^$1" || die "Membro '$1' não encontrado no .deb."
}

tar_flags() {  # $1 = nome do membro; imprime as flags de descompressão
    case "$1" in
        *.xz) command -v xz > /dev/null 2>&1 || die "Instale 'xz-utils' para descompactar o .deb." ; echo "-J" ;;
        *.gz) echo "-z" ;;
        *.bz2) echo "-j" ;;
        *.zst) command -v zstd > /dev/null 2>&1 || die "Instale 'zstd' para descompactar o .deb." ; echo "--zstd" ;;
        *.tar) echo "" ;;
        *) die "Compressão não suportada no .deb: $1" ;;
    esac
}

deb_field() {
    local field="$1" member

    if command -v dpkg-deb > /dev/null 2>&1; then
        dpkg-deb -f "$DEB_FILE" "$field"
        return
    fi

    command -v ar > /dev/null 2>&1 || die "Instale 'dpkg-deb' (dpkg) ou 'ar' (binutils) para ler o .deb."
    command -v tar > /dev/null 2>&1 || die "tar não encontrado."

    member=$(deb_member control.tar)
    ar p "$DEB_FILE" "$member" | tar -xO $(tar_flags "$member") ./control \
        | awk -F': *' -v k="$field" '$1 == k { print $2 }'
}

DEB_VERSION="$(deb_field Version)"
[ -n "$DEB_VERSION" ] || die "Não consegui ler a versão do .deb."
# Version do dpkg é "4.9-5" (revisão Debian); o app é 4.9.5
APP_VERSION="${DEB_VERSION//-/.}"
OUTPUT_NAME="ToneLib-GFX-${APP_VERSION}-x86_64.AppImage"

info "Versão do pacote: $DEB_VERSION (app $APP_VERSION)"

# ---------------------------------------------------------------------------
# Montar o AppDir
# ---------------------------------------------------------------------------
info "Extraindo o .deb..."
rm -rf "$BUILD_DIR"
mkdir -p "$APP_DIR/usr/bin" "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

if command -v dpkg-deb > /dev/null 2>&1; then
    dpkg-deb -x "$DEB_FILE" "$APP_DIR"
else
    command -v ar > /dev/null 2>&1 || die "Instale 'dpkg-deb' (dpkg) ou 'ar' (binutils)."
    member=$(deb_member data.tar)
    ar p "$DEB_FILE" "$member" | tar -x $(tar_flags "$member") -C "$APP_DIR"
fi

# Apenas o standalone: os .so de VST/VST3 dentro do squashfs não são utilizáveis
# por uma DAW e somariam ~100 MB à imagem.
rm -rf "$APP_DIR/usr/lib/vst" "$APP_DIR/usr/lib/vst3"

[ -x "$APP_DIR/usr/bin/ToneLib-GFX" ] || die "Binário ToneLib-GFX não encontrado no .deb."

# Ícone: usa o do pacote, com fallback para o PNG do repositório
ICON_SRC=""
for src in "$APP_DIR/usr/share/icons/ToneLib-GFX.png" \
           "$APP_DIR/usr/share/pixmaps/ToneLib-GFX.png" \
           "$REPO_DIR/tonelib-icon.png"; do
    [ -f "$src" ] && { ICON_SRC="$src"; break; }
done
[ -n "$ICON_SRC" ] || die "Ícone não encontrado."
cp "$ICON_SRC" "$APP_DIR/tonelib-gfx.png"
cp "$ICON_SRC" "$APP_DIR/.DirIcon"
cp "$ICON_SRC" "$APP_DIR/usr/share/icons/hicolor/256x256/apps/tonelib-gfx.png"

cat > "$APP_DIR/tonelib-gfx.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=ToneLib GFX
Comment=The amp and effects modeling software for electric guitar and bass
Exec=tonelib-gfx
Icon=tonelib-gfx
Categories=AudioVideo;AudioEditing;
Terminal=false
StartupWMClass=ToneLib GFX
X-AppImage-Version=${APP_VERSION}
EOF

cat > "$APP_DIR/AppRun" <<'EOF'
#!/bin/bash
# Wrapper do ToneLib-GFX dentro do AppImage
set -e
HERE="$(dirname "$(readlink -f "${0}")")"

# Mesmas variáveis usadas no container Docker
export QT_X11_NO_MITSHM=1
export QT_LOGGING_RULES="*.debug=false"
export PULSE_LATENCY_MSEC="${PULSE_LATENCY_MSEC:-20}"

exec "$HERE/usr/bin/ToneLib-GFX" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

# ---------------------------------------------------------------------------
# Runtime do AppImage
# ---------------------------------------------------------------------------
mkdir -p "$CACHE_DIR"
RUNTIME="$CACHE_DIR/runtime-x86_64-${RUNTIME_TAG}"

if [ ! -f "$RUNTIME" ]; then
    info "Baixando runtime do AppImage (${RUNTIME_TAG})..."
    curl -fL --retry 3 -sS -o "$RUNTIME.part" "$RUNTIME_URL" || { rm -f "$RUNTIME.part"; die "Falha ao baixar o runtime: $RUNTIME_URL"; }
    mv "$RUNTIME.part" "$RUNTIME"
fi

ACTUAL_SHA256=$(sha256sum "$RUNTIME" | cut -d' ' -f1)
if [ "$ACTUAL_SHA256" != "$RUNTIME_SHA256" ]; then
    die "sha256 do runtime não confere.
  esperado: $RUNTIME_SHA256
  obtido:   $ACTUAL_SHA256
  arquivo:  $RUNTIME
Se o runtime upstream foi republicado, atualize RUNTIME_SHA256 no script.
Para refazer o download: rm $RUNTIME"
fi

# ---------------------------------------------------------------------------
# Empacotar
# ---------------------------------------------------------------------------
info "Criando squashfs..."
mksquashfs "$APP_DIR" "$BUILD_DIR/ToneLib.squashfs" \
    -root-owned -noappend -comp zstd -b 131072 -no-progress -quiet

info "Concatenando runtime + squashfs..."
cat "$RUNTIME" "$BUILD_DIR/ToneLib.squashfs" > "$REPO_DIR/$OUTPUT_NAME"
chmod +x "$REPO_DIR/$OUTPUT_NAME"

rm -rf "$BUILD_DIR"

ok "AppImage gerado: $REPO_DIR/$OUTPUT_NAME"
info "Tamanho: $(du -h "$REPO_DIR/$OUTPUT_NAME" | cut -f1)"
info "sha256:  $(sha256sum "$REPO_DIR/$OUTPUT_NAME" | cut -d' ' -f1)"
echo ""
echo "Execute com:"
echo "  ./$OUTPUT_NAME"
echo ""
echo "Requisitos no host: x86_64, glibc >= 2.27, X11 ou XWayland, driver OpenGL,"
echo "ALSA ou PulseAudio. Se faltar FUSE, use: APPIMAGE_EXTRACT_AND_RUN=1 ./$OUTPUT_NAME"
