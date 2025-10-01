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

# Criar diretório home do ToneLib se não existir
TONELIB_HOME="$HOME/tonelib"
if [ ! -d "$TONELIB_HOME" ]; then
    echo -e "${GREEN}[SETUP]${NC} Criando diretório ToneLib em $TONELIB_HOME..."
    mkdir -p "$TONELIB_HOME"

    # Copiar README para o diretório
    if [ -f "ToneLib-Files-README.md" ]; then
        cp ToneLib-Files-README.md "$TONELIB_HOME/README.md"
    fi

    echo -e "${YELLOW}[INFO]${NC} Diretório ToneLib criado!"
    echo -e "${YELLOW}[INFO]${NC} Localização: $TONELIB_HOME"
    echo -e "${YELLOW}[INFO]${NC} Gravações estarão em: $TONELIB_HOME/Music/GFX-Recordings"
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
