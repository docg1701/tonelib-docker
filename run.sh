#!/bin/bash

# Script para executar o ToneLib-GFX no Docker com suporte gráfico e áudio
# Baixa o .deb mais recente se necessário e reconstrói a imagem quando ele muda.
#
# Ao ser executado sem root, pede a senha via sudo e segue rodando como root
# (a partir daí instala dependências e fala com o daemon sem novo prompt).

set -e

REPO_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
cd "$REPO_DIR"

DEB_FILE="ToneLib-GFX-amd64.deb"
DEB_URL="https://tonelib.net/download.php?id=gfx&os=lnx"
IMAGE="tonelib-gfx:latest"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${YELLOW}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
die() { echo -e "${RED}[ERRO]${NC} $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Elevação: contexto do usuário + sudo se necessário
# ---------------------------------------------------------------------------
[ -f "$REPO_DIR/lib/root.sh" ] || die "Arquivo lib/root.sh não encontrado (clone incompleto?)."
# shellcheck source=lib/root.sh
. "$REPO_DIR/lib/root.sh"

parse_sudo_context "$@"
set -- "${SCRIPT_ARGS[@]}"

# --update força baixar a versão publicada mais recente
UPDATE=0
case "${1:-}" in
    --update) UPDATE=1 ;;
    -h|--help)
        echo "Uso: ./run.sh [--update]"
        echo ""
        echo "  (sem argumentos)  usa o $DEB_FILE local ou baixa se não existir"
        echo "  --update          baixa novamente a versão mais recente de tonelib.net"
        echo ""
        echo "O script pede a senha do sudo e roda como root (instala Docker se faltar)."
        exit 0
        ;;
    "") ;;
    *) die "Argumento desconhecido: $1 (use --help)" ;;
esac

ensure_root "$REPO_DIR/run.sh" "$@"

echo -e "${GREEN}[ToneLib-GFX Docker]${NC} Preparando ambiente..."
info "Usuário dono dos arquivos: $ORIG_USER ($ORIG_UID:$ORIG_GID)"

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------
if ! command -v docker > /dev/null 2>&1; then
    info "Docker não encontrado. Instalando via script oficial (get.docker.com)..."
    require_tool curl curl || die "Sem curl não é possível baixar o instalador do Docker."
    DOCKER_INSTALLER=$(mktemp /tmp/get-docker-XXXXXX.sh)
    curl -fsSL https://get.docker.com -o "$DOCKER_INSTALLER" \
        || { rm -f "$DOCKER_INSTALLER"; die "Falha ao baixar https://get.docker.com"; }
    sh "$DOCKER_INSTALLER" || { rm -f "$DOCKER_INSTALLER"; die "Instalador do Docker falhou."; }
    rm -f "$DOCKER_INSTALLER"
    command -v docker > /dev/null 2>&1 || die "Docker não apareceu no PATH após a instalação."
    ok "Docker instalado."
fi

if ! docker compose version > /dev/null 2>&1; then
    info "Plugin 'docker compose' não encontrado. Instalando..."
    COMPOSE_PKG="docker-compose"
    [ "$(detect_pm || true)" = "dnf" ] && COMPOSE_PKG="docker-compose-plugin"
    pm_install "$COMPOSE_PKG" || die "Não foi possível instalar o plugin Docker Compose v2."
fi
docker compose version > /dev/null 2>&1 || die "Docker Compose v2 indisponível (plugin 'docker compose')."

if ! docker info > /dev/null 2>&1; then
    info "Daemon do Docker não está acessível. Subindo o serviço..."
    systemctl enable --now docker || true
    sleep 2
    docker info > /dev/null 2>&1 || die "O daemon do Docker não subiu. Veja: journalctl -u docker"
fi

# O socket do daemon exige o grupo docker; o script roda como root, então isso
# só importa para usar o docker depois, sem sudo.
if [ "$ORIG_UID" != "0" ] && ! id -nG "$ORIG_USER" 2> /dev/null | grep -qw docker; then
    if usermod -aG docker "$ORIG_USER" 2> /dev/null; then
        info "Usuário $ORIG_USER adicionado ao grupo docker (vale no próximo login)."
    fi
fi

# ---------------------------------------------------------------------------
# Download do .deb oficial
# ---------------------------------------------------------------------------
download_deb() {
    local tmp="${DEB_FILE}.part"
    info "Baixando ToneLib-GFX mais recente de tonelib.net..."
    rm -f "$tmp"
    curl -fL --retry 3 --connect-timeout 20 -o "$tmp" "$DEB_URL" \
        || { rm -f "$tmp"; die "Falha no download. Baixe manualmente de https://tonelib.net/gfx-overview/ e salve como $DEB_FILE"; }

    # O site pode devolver uma página de erro com status 200; valida o pacote.
    if [ "$(head -c 8 "$tmp")" != '!<arch>' ]; then
        rm -f "$tmp"
        die "O download não é um .deb válido. Baixe manualmente de https://tonelib.net/gfx-overview/"
    fi
    mv "$tmp" "$DEB_FILE"
    give_back "$DEB_FILE"
    ok "Download concluído: $DEB_FILE"
    if command -v dpkg-deb > /dev/null 2>&1; then
        info "Versão do pacote: $(dpkg-deb -f "$DEB_FILE" Version)"
    fi
}

if [ "$UPDATE" -eq 1 ] || [ ! -f "$DEB_FILE" ]; then
    download_deb
fi

# ---------------------------------------------------------------------------
# X11
# ---------------------------------------------------------------------------
info "Permitindo conexões X11..."
if [ -z "$ORIG_DISPLAY" ]; then
    die "DISPLAY vazio. Rode o script dentro da sessão gráfica (terminal com X11/Wayland)."
fi
xhost +local:docker > /dev/null 2>&1 || {
    echo -e "${YELLOW}[AVISO]${NC} Não foi possível configurar xhost. Interface gráfica pode não funcionar."
}

# Variáveis usadas pelo compose.yml (dono real dos arquivos, não o root)
export USER_ID="$ORIG_UID"
export GROUP_ID="$ORIG_GID"
export DISPLAY="$ORIG_DISPLAY"

# Criar diretório home do ToneLib se não existir
TONELIB_HOME="$ORIG_HOME/tonelib"
if [ ! -d "$TONELIB_HOME" ]; then
    echo -e "${GREEN}[SETUP]${NC} Criando diretório ToneLib em $TONELIB_HOME..."
    mkdir -p "$TONELIB_HOME"

    # Copiar README para o diretório
    if [ -f "ToneLib-Files-README.md" ]; then
        cp ToneLib-Files-README.md "$TONELIB_HOME/README.md"
    fi

    give_back "$TONELIB_HOME"
    info "Diretório ToneLib criado!"
    info "Gravações estarão em: $TONELIB_HOME/Music/GFX-Recordings"
fi

# ---------------------------------------------------------------------------
# Build: só quando a imagem não existe ou o .deb local mudou
# ---------------------------------------------------------------------------
TONELIB_DEB_SHA=$(sha256sum "$DEB_FILE" | cut -d' ' -f1)
export TONELIB_DEB_SHA

IMAGE_SHA=$(docker image inspect -f '{{index .Config.Labels "tonelib.deb.sha256"}}' "$IMAGE" 2> /dev/null || true)

if [ -z "$IMAGE_SHA" ] || [ "$IMAGE_SHA" != "$TONELIB_DEB_SHA" ]; then
    echo -e "${GREEN}[BUILD]${NC} Construindo imagem Docker..."
    # O Dockerfile usa RUN --mount=type=bind, que exige BuildKit
    export DOCKER_BUILDKIT=1
    docker compose build
else
    info "Imagem já corresponde ao $DEB_FILE local (sha256: ${TONELIB_DEB_SHA:0:12})."
fi

# ---------------------------------------------------------------------------
# Execução
# ---------------------------------------------------------------------------
echo -e "${GREEN}[START]${NC} Iniciando ToneLib-GFX..."
docker compose up

# Cleanup ao sair
echo -e "${GREEN}[CLEANUP]${NC} Limpando permissões X11..."
xhost -local:docker > /dev/null 2>&1 || true

echo -e "${GREEN}[OK]${NC} Finalizado!"
