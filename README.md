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
git clone https://github.com/YOUR_USERNAME/tonelib-docker.git
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

Files in `~/ToneLib-Files/` are accessible in ToneLib-GFX at `/home/tonelib/ToneLib-Files/`.

Use for backing tracks, IRs, presets, etc.

```bash
# Example
cp ~/Downloads/*.mp3 ~/ToneLib-Files/
```

### Audio Latency

**For home practice:** Works perfectly (10-20ms total).

**Tips:**
- Use dedicated USB audio interface (not onboard)
- Set buffer to 128-256 samples in ToneLib-GFX
- Close other audio apps

**Not recommended for:** Professional live shows or critical studio recording.

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
~/ToneLib-Files/          # Shared folder (created automatically)
tonelib-docker/
├── Dockerfile
├── compose.yml
├── run.sh
├── install-desktop.sh
└── ToneLib-GFX-amd64.deb # (you add this)
```

### Why Ubuntu 20.04?

Last LTS release with `libgl1-mesa-glx` and `libcurl3-gnutls`. Newer versions removed these packages.

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
git clone https://github.com/SEU_USUARIO/tonelib-docker.git
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

Arquivos em `~/ToneLib-Files/` ficam acessíveis no ToneLib-GFX em `/home/tonelib/ToneLib-Files/`.

Use para backing tracks, IRs, presets, etc.

```bash
# Exemplo
cp ~/Downloads/*.mp3 ~/ToneLib-Files/
```

### Latência de Áudio

**Para prática em casa:** Funciona perfeitamente (10-20ms total).

**Dicas:**
- Use interface USB dedicada (não onboard)
- Configure buffer 128-256 samples no ToneLib-GFX
- Feche outros apps de áudio

**Não recomendado para:** Shows ao vivo profissionais ou gravação crítica de estúdio.

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
~/ToneLib-Files/          # Pasta compartilhada (criada automaticamente)
tonelib-docker/
├── Dockerfile
├── compose.yml
├── run.sh
├── install-desktop.sh
└── ToneLib-GFX-amd64.deb # (você adiciona)
```

### Por que Ubuntu 20.04?

Última versão LTS com `libgl1-mesa-glx` e `libcurl3-gnutls`. Versões mais novas removeram esses pacotes.

### Licença

MIT - Apenas para arquivos de configuração Docker.

ToneLib-GFX é propriedade da ToneLib Team.

---

**Problemas?** Abra uma [issue](https://github.com/SEU_USUARIO/tonelib-docker/issues).
