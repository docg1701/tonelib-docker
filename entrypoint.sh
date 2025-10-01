#!/bin/bash
# Script de inicialização inteligente para ToneLib-GFX
# Detecta e configura automaticamente o melhor backend de áudio disponível

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}[ToneLib-GFX]${NC} Inicializando..."

# Função para detectar JACK
detect_jack() {
    if command -v jack_lsp &> /dev/null; then
        if jack_lsp &> /dev/null; then
            return 0  # JACK está rodando
        fi
    fi
    return 1  # JACK não disponível
}

# Função para detectar PulseAudio
detect_pulseaudio() {
    if [ -S "/run/user/$(id -u)/pulse/native" ]; then
        return 0  # PulseAudio disponível
    fi
    return 1  # PulseAudio não disponível
}

# Detectar e configurar áudio
echo -e "${BLUE}[INFO]${NC} Detectando sistema de áudio..."

if detect_jack; then
    echo -e "${GREEN}[JACK]${NC} JACK Audio detectado - Usando JACK para baixa latência"
    export JACK_DEFAULT_SERVER=default
    export LATENCY_INFO="~3-5ms (JACK)"
    AUDIO_BACKEND="JACK"
elif detect_pulseaudio; then
    echo -e "${YELLOW}[PulseAudio]${NC} PulseAudio detectado - Latência moderada"
    # Configurar latência do PulseAudio
    export PULSE_LATENCY_MSEC=${PULSE_LATENCY_MSEC:-20}
    export LATENCY_INFO="~10-20ms (PulseAudio)"
    AUDIO_BACKEND="PulseAudio"
else
    echo -e "${YELLOW}[AVISO]${NC} Nenhum sistema de áudio detectado, tentando ALSA direto"
    export LATENCY_INFO="Desconhecida (ALSA)"
    AUDIO_BACKEND="ALSA"
fi

# Configurações Qt para melhor performance
export QT_X11_NO_MITSHM=1
export QT_LOGGING_RULES="*.debug=false"

# Informações do sistema de áudio
echo -e "${BLUE}[INFO]${NC} Backend de áudio: ${AUDIO_BACKEND}"
echo -e "${BLUE}[INFO]${NC} Latência esperada: ${LATENCY_INFO}"

# Verificar se diretório home está montado
if mountpoint -q /home/tonelib 2>/dev/null || [ -w /home/tonelib ]; then
    echo -e "${GREEN}[OK]${NC} Diretório home montado e acessível"
    echo -e "${BLUE}[INFO]${NC} Gravações em: /home/tonelib/Music/GFX-Recordings"
else
    echo -e "${YELLOW}[AVISO]${NC} Diretório home não está montado corretamente"
fi

# Iniciar ToneLib-GFX
echo -e "${GREEN}[START]${NC} Iniciando ToneLib-GFX..."
echo ""

exec /usr/bin/ToneLib-GFX "$@"
