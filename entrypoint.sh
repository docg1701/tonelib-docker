#!/bin/bash
# Script de inicialização para ToneLib-GFX
# Configurado para usar PulseAudio

set -e

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}[ToneLib-GFX]${NC} Inicializando..."

# Configurar PulseAudio
export PULSE_LATENCY_MSEC=${PULSE_LATENCY_MSEC:-20}

# Configurações Qt para melhor performance
export QT_X11_NO_MITSHM=1
export QT_LOGGING_RULES="*.debug=false"

# Informações do sistema de áudio
echo -e "${BLUE}[INFO]${NC} Sistema de áudio: PulseAudio"
echo -e "${BLUE}[INFO]${NC} Latência configurada: ~10-20ms"

# Verificar se diretório home está montado
if mountpoint -q /home/tonelib 2>/dev/null || [ -w /home/tonelib ]; then
    echo -e "${GREEN}[OK]${NC} Diretório home montado e acessível"
    echo -e "${BLUE}[INFO]${NC} Gravações em: /home/tonelib/Music/GFX-Recordings"
fi

# Iniciar ToneLib-GFX
echo -e "${GREEN}[START]${NC} Iniciando ToneLib-GFX..."
echo ""

exec /usr/bin/ToneLib-GFX "$@"
