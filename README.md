# 🎸 ToneLib-GFX Docker

[English](#english) | [Português](#português)

---

## English

Run **ToneLib-GFX** on modern Linux distributions using Docker.

### The Problem

ToneLib-GFX `.deb` package depends on libraries that no longer exist on Ubuntu 22.04+, Linux Mint 21+, Debian 12+:

```
Package libgl1-mesa-glx is not installable
Package libcurl3-gnutls is not installable
```

### The Solution

Docker container with Ubuntu 20.04 that has all the necessary dependencies.

### Installation

#### 1. Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Download ToneLib-GFX

Download the `.deb` file from the [official website](https://tonelib.net/gfx-overview/).

#### 3. Clone and prepare

```bash
git clone https://github.com/docg1701/tonelib-docker.git
cd tonelib-docker
mv ~/Downloads/ToneLib-GFX-amd64.deb .
```

#### 4. Run

```bash
./run.sh
```

Done! The application opens with GUI and working audio.

### Add to Menu

```bash
./install-desktop.sh
```

Will appear in: Menu → Multimedia → ToneLib GFX (Docker)

### Shared Folder

The entire ToneLib home directory `~/tonelib/` is shared with the container.

**Useful directories:**
- `~/tonelib/` - Add your backing tracks, IRs, presets here
- `~/tonelib/Music/GFX-Recordings/` - Your recordings will be saved here
- All files are directly accessible from ToneLib-GFX

```bash
# Example: Add backing tracks
cp ~/Downloads/*.mp3 ~/tonelib/

# Example: Access recordings
ls ~/tonelib/Music/GFX-Recordings/
```

### Audio Latency

The container automatically detects and configures the best available audio backend:

#### 🎯 PulseAudio (Default)
- **Latency:** ~10-20ms total
- **Setup:** Works out of the box
- **Best for:** Home practice, jamming along tracks
- **Configuration:** Buffer size 128-256 samples in ToneLib-GFX

#### ⚡ JACK Audio (Low Latency)
- **Latency:** ~3-5ms total
- **Setup:** Install JACK on host and start before running container
- **Best for:** Real-time playing, recording
- **Auto-detected:** Container switches to JACK automatically if available

**Tips for best performance:**
- Use dedicated USB audio interface (not onboard)
- Close other audio applications
- For JACK: Install `jackd2` and `qjackctl` on your host system
- Adjust buffer size in ToneLib-GFX settings (128 samples recommended)

### Troubleshooting

#### Application doesn't open

```bash
xhost +local:docker
```

#### No audio

```bash
pulseaudio --check || pulseaudio --start
```

#### Check audio interface

```bash
docker compose run --rm tonelib-gfx aplay -l
```

#### Clean and rebuild

```bash
docker compose down
docker rmi tonelib-gfx:latest
docker compose build --no-cache
```

### Structure

```
~/tonelib/                      # ToneLib home directory (created automatically)
  ├── Music/
  │   └── GFX-Recordings/      # Your recordings
  └── (your backing tracks, IRs, presets)

tonelib-docker/
├── Dockerfile
├── compose.yml
├── entrypoint.sh
├── run.sh
├── install-desktop.sh
└── ToneLib-GFX-amd64.deb       # (you add this)
```

### Why Ubuntu 20.04?

Last LTS release with `libgl1-mesa-glx` and `libcurl3-gnutls`. Newer versions removed these packages.

### Support the Project

If this project helped you, consider supporting its development:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/docg1701)

### License

MIT - For Docker configuration files only.

ToneLib-GFX is property of ToneLib Team.

---

**Issues?** Open an [issue](https://github.com/YOUR_USERNAME/tonelib-docker/issues).

---

## Português

Execute o **ToneLib-GFX** em distribuições Linux modernas usando Docker.

### O Problema

O pacote `.deb` do ToneLib-GFX depende de bibliotecas que não existem mais no Ubuntu 22.04+, Linux Mint 21+, Debian 12+:

```
Package libgl1-mesa-glx is not installable
Package libcurl3-gnutls is not installable
```

### A Solução

Container Docker com Ubuntu 20.04 que possui todas as dependências necessárias.

### Instalação

#### 1. Instalar Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Baixar o ToneLib-GFX

Baixe o arquivo `.deb` do [site oficial](https://tonelib.net/gfx-overview/).

#### 3. Clonar e preparar

```bash
git clone https://github.com/docg1701/tonelib-docker.git
cd tonelib-docker
mv ~/Downloads/ToneLib-GFX-amd64.deb .
```

#### 4. Executar

```bash
./run.sh
```

Pronto! O aplicativo abre com interface gráfica e áudio funcionando.

### Adicionar ao Menu

```bash
./install-desktop.sh
```

Aparecerá em: Menu → Multimídia → ToneLib GFX (Docker)

### Pasta Compartilhada

O diretório home completo do ToneLib `~/tonelib/` é compartilhado com o container.

**Diretórios úteis:**
- `~/tonelib/` - Adicione backing tracks, IRs, presets aqui
- `~/tonelib/Music/GFX-Recordings/` - Suas gravações serão salvas aqui
- Todos os arquivos são diretamente acessíveis do ToneLib-GFX

```bash
# Exemplo: Adicionar backing tracks
cp ~/Downloads/*.mp3 ~/tonelib/

# Exemplo: Acessar gravações
ls ~/tonelib/Music/GFX-Recordings/
```

### Latência de Áudio

O container detecta e configura automaticamente o melhor backend de áudio disponível:

#### 🎯 PulseAudio (Padrão)
- **Latência:** ~10-20ms total
- **Configuração:** Funciona imediatamente
- **Ideal para:** Prática em casa, tocar junto com músicas
- **Configuração:** Buffer de 128-256 samples no ToneLib-GFX

#### ⚡ JACK Audio (Baixa Latência)
- **Latência:** ~3-5ms total
- **Configuração:** Instale JACK no host e inicie antes de executar o container
- **Ideal para:** Tocar em tempo real, gravação
- **Auto-detectado:** Container muda para JACK automaticamente se disponível

**Dicas para melhor performance:**
- Use interface USB dedicada (não onboard)
- Feche outras aplicações de áudio
- Para JACK: Instale `jackd2` e `qjackctl` no seu sistema host
- Ajuste buffer no ToneLib-GFX (128 samples recomendado)

### Troubleshooting

#### Aplicativo não abre

```bash
xhost +local:docker
```

#### Sem áudio

```bash
pulseaudio --check || pulseaudio --start
```

#### Verificar interface de áudio

```bash
docker compose run --rm tonelib-gfx aplay -l
```

#### Limpar e reconstruir

```bash
docker compose down
docker rmi tonelib-gfx:latest
docker compose build --no-cache
```

### Estrutura

```
~/tonelib/                      # Diretório home do ToneLib (criado automaticamente)
  ├── Music/
  │   └── GFX-Recordings/      # Suas gravações
  └── (backing tracks, IRs, presets)

tonelib-docker/
├── Dockerfile
├── compose.yml
├── entrypoint.sh
├── run.sh
├── install-desktop.sh
└── ToneLib-GFX-amd64.deb       # (você adiciona)
```

### Por que Ubuntu 20.04?

Última versão LTS com `libgl1-mesa-glx` e `libcurl3-gnutls`. Versões mais novas removeram esses pacotes.

### Apoie o Projeto

Se este projeto te ajudou, considere apoiar seu desenvolvimento:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/docg1701)

### Licença

MIT - Apenas para arquivos de configuração Docker.

ToneLib-GFX é propriedade da ToneLib Team.

---

**Problemas?** Abra uma [issue](https://github.com/SEU_USUARIO/tonelib-docker/issues).
