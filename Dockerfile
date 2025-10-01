FROM ubuntu:20.04

# Evitar prompts interativos durante instalação
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências do sistema e bibliotecas gráficas/áudio
RUN apt-get update && apt-get install -y \
    libcurl3-gnutls \
    libfreetype6 \
    libgl1-mesa-glx \
    libgl1-mesa-dri \
    libglu1-mesa \
    libx11-6 \
    libxext6 \
    libxinerama1 \
    libasound2 \
    libpulse0 \
    pulseaudio-utils \
    alsa-utils \
    libxrandr2 \
    libxcursor1 \
    libxi6 \
    libxrender1 \
    libxfixes3 \
    libxcomposite1 \
    libxdamage1 \
    libxshmfence1 \
    ca-certificates \
    fontconfig \
    fonts-dejavu-core \
    fonts-liberation \
    fonts-freefont-ttf \
    x11-utils \
    && rm -rf /var/lib/apt/lists/*

# Copiar o arquivo .deb para o container
COPY ToneLib-GFX-amd64.deb /tmp/

# Instalar o ToneLib-GFX
RUN dpkg -i /tmp/ToneLib-GFX-amd64.deb || true && \
    apt-get update && \
    apt-get -f install -y && \
    rm /tmp/ToneLib-GFX-amd64.deb && \
    rm -rf /var/lib/apt/lists/*

# Criar usuário não-root com mesmo UID/GID do host
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} tonelib && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -G audio -m -s /bin/bash tonelib

# Configurar PulseAudio para cliente
RUN mkdir -p /home/tonelib/.config/pulse && \
    echo "default-server = unix:/run/user/${USER_ID}/pulse/native" > /home/tonelib/.config/pulse/client.conf && \
    chown -R tonelib:tonelib /home/tonelib/.config

USER tonelib
WORKDIR /home/tonelib

# Comando padrão: executar o ToneLib-GFX
CMD ["/usr/bin/ToneLib-GFX"]
