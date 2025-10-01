#!/bin/bash

# Script para executar o ToneLib-GFX no Docker com suporte gráfico e áudio

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[ToneLib-GFX Docker]${NC} Preparando ambiente..."

# Permitir conexões X11 do container
echo -e "${YELLOW}[INFO]${NC} Permitindo conexões X11..."
xhost +local:docker > /dev/null 2>&1 || {
    echo -e "${YELLOW}[AVISO]${NC} Não foi possível configurar xhost. Interface gráfica pode não funcionar."
}

# Exportar variáveis de ambiente
export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

# Criar pasta compartilhada se não existir
SHARED_DIR="$HOME/ToneLib-Files"
if [ ! -d "$SHARED_DIR" ]; then
    echo -e "${GREEN}[SETUP]${NC} Criando pasta compartilhada em $SHARED_DIR..."
    mkdir -p "$SHARED_DIR"

    # Copiar README para a pasta compartilhada
    if [ -f "ToneLib-Files-README.md" ]; then
        cp ToneLib-Files-README.md "$SHARED_DIR/README.md"
    fi

    echo -e "${YELLOW}[INFO]${NC} Pasta compartilhada criada!"
    echo -e "${YELLOW}[INFO]${NC} Localização: $SHARED_DIR"
fi

# Verificar se o arquivo .deb existe
if [ ! -f "ToneLib-GFX-amd64.deb" ]; then
    echo -e "${YELLOW}[ERRO]${NC} Arquivo ToneLib-GFX-amd64.deb não encontrado!"
    exit 1
fi

# Verificar se precisa fazer build
if [ ! "$(docker images -q tonelib-gfx:latest 2> /dev/null)" ]; then
    echo -e "${GREEN}[BUILD]${NC} Construindo imagem Docker (primeira execução)..."
    docker compose build
fi

# Iniciar o container
echo -e "${GREEN}[START]${NC} Iniciando ToneLib-GFX..."
docker compose up

# Cleanup ao sair
echo -e "${GREEN}[CLEANUP]${NC} Limpando permissões X11..."
xhost -local:docker > /dev/null 2>&1 || true

echo -e "${GREEN}[OK]${NC} Finalizado!"
