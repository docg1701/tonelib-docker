#!/bin/bash

# Script para executar o ToneLib-GFX no Docker com suporte gráfico e áudio
# Baixa o .deb mais recente se necessário e reconstrói a imagem quando ele muda.

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

# --update força baixar a versão publicada mais recente
UPDATE=0
case "${1:-}" in
    --update) UPDATE=1 ;;
    -h|--help)
        echo "Uso: ./run.sh [--update]"
        echo ""
        echo "  (sem argumentos)  usa o $DEB_FILE local ou baixa se não existir"
        echo "  --update          baixa novamente a versão mais recente de tonelib.net"
        exit 0
        ;;
    "") ;;
    *) die "Argumento desconhecido: $1 (use --help)" ;;
esac

echo -e "${GREEN}[ToneLib-GFX Docker]${NC} Preparando ambiente..."

# ---------------------------------------------------------------------------
# Docker (instalação/credenciais pedem sudo via lib/prompt.sh)
# ---------------------------------------------------------------------------
[ -f "$REPO_DIR/lib/prompt.sh" ] || die "Arquivo lib/prompt.sh não encontrado (clone incompleto?)."
# shellcheck source=lib/prompt.sh
. "$REPO_DIR/lib/prompt.sh"

if ! command -v docker > /dev/null 2>&1; then
    info "Docker não encontrado."
    require_tool curl curl || die "Sem curl não é possível baixar o instalador do Docker."

    # Baixa o instalador para um arquivo para que o comando mostrado no prompt
    # seja o que de fato roda (nada de 'curl ... | sudo bash' truncado)
    DOCKER_INSTALLER=$(mktemp /tmp/get-docker-XXXXXX.sh)
    if curl -fsSL https://get.docker.com -o "$DOCKER_INSTALLER" \
            && ask_sudo "instalar o Docker (script oficial get.docker.com)" sh "$DOCKER_INSTALLER"; then
        rm -f "$DOCKER_INSTALLER"
        ok "Docker instalado."
    else
        rm -f "$DOCKER_INSTALLER"
        die "Instale o Docker manualmente: https://docs.docker.com/engine/install/"
    fi
fi

if ! docker compose version > /dev/null 2>&1; then
    info "Plugin 'docker compose' não encontrado."
    COMPOSE_PKG="docker-compose"
    [ "$(detect_pm || true)" = "dnf" ] && COMPOSE_PKG="docker-compose-plugin"
    pm_install "$COMPOSE_PKG" || die "Instale o plugin Docker Compose v2 e rode novamente."
fi
docker compose version > /dev/null 2>&1 || die "Docker Compose v2 indisponível (plugin 'docker compose')."

# Daemon rodando e usuário com permissão no socket
if ! docker info > /dev/null 2>&1; then
    info "Sem acesso ao daemon do Docker."
    ask_sudo "iniciar e habilitar o serviço docker" systemctl enable --now docker || true

    if ! docker info > /dev/null 2>&1; then
        if id -nG "$USER" 2> /dev/null | grep -qw docker; then
            die "Você está no grupo 'docker' mas sem acesso ao socket. Rode 'newgrp docker' (ou relogue) e tente de novo."
        fi
        if ask_sudo "adicionar o usuário $USER ao grupo docker" usermod -aG docker "$USER"; then
            ok "Usuário $USER adicionado ao grupo docker."
            die "Rode 'newgrp docker' (ou relogue) e execute ./run.sh de novo."
        fi
        die "Sem acesso ao Docker. Rode: sudo usermod -aG docker $USER && newgrp docker"
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
xhost +local:docker > /dev/null 2>&1 || {
    echo -e "${YELLOW}[AVISO]${NC} Não foi possível configurar xhost. Interface gráfica pode não funcionar."
}

# Exportar variáveis de ambiente usadas pelo compose.yml
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)
export DISPLAY="${DISPLAY:-:0}"

# Criar diretório home do ToneLib se não existir
TONELIB_HOME="$HOME/tonelib"
if [ ! -d "$TONELIB_HOME" ]; then
    echo -e "${GREEN}[SETUP]${NC} Criando diretório ToneLib em $TONELIB_HOME..."
    mkdir -p "$TONELIB_HOME"

    # Copiar README para o diretório
    if [ -f "ToneLib-Files-README.md" ]; then
        cp ToneLib-Files-README.md "$TONELIB_HOME/README.md"
    fi

    info "Diretório ToneLib criado!"
    info "Gravações estarão em: $TONELIB_HOME/Music/GFX-Recordings"
fi

# ---------------------------------------------------------------------------
# Build: só quando a imagem não existe ou o .deb local mudou
# ---------------------------------------------------------------------------
export TONELIB_DEB_SHA
TONELIB_DEB_SHA=$(sha256sum "$DEB_FILE" | cut -d' ' -f1)

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
