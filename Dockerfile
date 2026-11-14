# syntax=docker/dockerfile:1

FROM ubuntu:24.04

# Evitar prompts interativos durante instalação
ENV DEBIAN_FRONTEND=noninteractive

# Dependências que o ToneLib-GFX realmente carrega em runtime.
# O binário embute Qt5 estaticamente: das libs abaixo só libasound, libGL,
# libfontconfig e libfreetype são DT_NEEDED; o resto (X11, Xext, Xinerama,
# Xcursor, Xrandr, Xrender, Xss, libcurl-gnutls, libjack) é carregado por dlopen.
# Não instale qtbase5-dev/libqt5*/libgtk-3-0: nada disso é usado.
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Base e utilitários
    ca-certificates \
    fontconfig \
    fonts-dejavu-core \
    procps \
    x11-utils \
    # Áudio: ALSA + plugin de saída PulseAudio + utilitários
    libasound2t64 \
    libasound2-plugins \
    libpulse0 \
    pulseaudio-utils \
    alsa-utils \
    # OpenGL/GLX (inclui driver software llvmpipe para hosts sem DRI)
    libgl1 \
    libglx-mesa0 \
    libgl1-mesa-dri \
    # Bibliotecas X11 carregadas pelo app
    libx11-6 \
    libxext6 \
    libxinerama1 \
    libxcursor1 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    # Renderização de texto
    libfontconfig1 \
    libfreetype6 \
    # Assets online (dlopen libcurl-gnutls) e suporte a JACK (dlopen libjack)
    libcurl3t64-gnutls \
    libjack-jackd2-0 \
    # Compat: libasound2 antigo é fornecido por libasound2t64
    && rm -rf /var/lib/apt/lists/*

# Instalar o ToneLib-GFX.
# O .deb oficial declara dependências que só existem até o Ubuntu 22.04
# (libgl1-mesa-glx, libgcc1, libcurl3-gnutls), então `dpkg -i` falha no 24.04.
# Como o binário é Qt5 estático e não usa essas libs de verdade, extraímos os
# arquivos direto na raiz. O bind mount evita guardar os ~100 MB do .deb numa
# camada da imagem.
RUN --mount=type=bind,source=ToneLib-GFX-amd64.deb,target=/tmp/ToneLib-GFX-amd64.deb,ro \
    dpkg-deb -x /tmp/ToneLib-GFX-amd64.deb /

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

# Criar usuário não-root com mesmo UID/GID do host
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} tonelib && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -G audio -m -s /bin/bash tonelib

# Configurar PulseAudio para cliente
RUN mkdir -p /home/tonelib/.config/pulse && \
    echo "default-server = unix:/run/user/${USER_ID}/pulse/native" > /home/tonelib/.config/pulse/client.conf && \
    chown -R tonelib:tonelib /home/tonelib/.config

# Hash do .deb usado no build: run.sh compara com o hash do arquivo local
# para saber se a imagem precisa ser reconstruída.
ARG TONELIB_DEB_SHA=unknown
LABEL tonelib.deb.sha256=${TONELIB_DEB_SHA}

USER tonelib
WORKDIR /home/tonelib

# Healthcheck: verifica se o ToneLib está rodando
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD pgrep -f "ToneLib" || exit 1

# Script de inicialização inteligente
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
