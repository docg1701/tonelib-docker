# 🎸 ToneLib-GFX — Docker + AppImage

[English](#english) | [Português](#português)

---

## English

Run **ToneLib-GFX 4.9.5** on modern Linux distributions — either as a standalone
**AppImage** built locally from the official `.deb`, or inside a **Docker** container.

### The Problem

The official ToneLib-GFX `.deb` declares dependencies that no longer exist on
Ubuntu 22.04+/24.04, Linux Mint 21+, Debian 12+:

```
Package libgl1-mesa-glx is not installable
Package libcurl3-gnutls is not installable
Package libgcc1 is not installable
```

`dpkg -i ToneLib-GFX-amd64.deb` therefore fails with unmet dependencies. The
binary itself does not need any of those libraries: it ships a **statically
linked Qt5** and only loads `libc`, `libm`, `libasound`, `libGL`,
`libfontconfig` and `libfreetype` (everything else — X11, `libcurl-gnutls`,
`libjack` — is loaded with `dlopen` at runtime).

### License note

ToneLib-GFX is proprietary. This repository **does not distribute the `.deb`,
the AppImage or any ToneLib binary** — it only contains configuration and build
scripts. You download the `.deb` from the official site yourself and build
locally.

### Download ToneLib-GFX

Get `ToneLib-GFX-amd64.deb` (Ubuntu 64-bit) from the
[official site](https://tonelib.net/gfx-overview/) and put it in the repository
root.

```bash
git clone https://github.com/docg1701/tonelib-docker.git
cd tonelib-docker
mv ~/Downloads/ToneLib-GFX-amd64.deb .
```

### Option 1 — AppImage (no Docker)

Requirements: x86_64, glibc ≥ 2.27 (any distro from 2018 onwards), X11 or
XWayland, a working OpenGL driver, ALSA or PulseAudio.

```bash
./build-appimage.sh          # --download baixa o .deb se ele não estiver aqui
./ToneLib-GFX-amd64.AppImage
```

If you run it as a normal user, the script asks for your `sudo` password and
from then on **runs as root**, installing `squashfs-tools`/`curl`
(`apt`/`dnf`/`pacman`) if they are missing. Files it creates are handed back to
your user at the end, so you never end up with root-owned files in the
repository. The AppImage keeps the same base name as the `.deb`
(`ToneLib-GFX-amd64.AppImage`); the version is reported by the script and kept
in the desktop entry (`X-AppImage-Version`).

`build-appimage.sh` unpacks the `.deb`, adds an `AppRun` wrapper and packs
everything into a single executable file (runtime + squashfs). It also prints
the size and sha256 of the result.

What is inside the AppImage: the ToneLib binary, icons and desktop entry.
What comes from the host: glibc, X11/XWayland, the OpenGL driver and the audio
stack. Bundling glibc, `libGL` or `libX11` is what breaks AppImages, so those
are intentionally left to the host (standard AppImage practice).

If FUSE is not available (e.g. some containers, or Ubuntu 24.04 without
`libfuse2t64`):

```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./ToneLib-GFX-amd64.AppImage
```

The VST/VST3 plugins from the `.deb` are **not** included in the AppImage —
a DAW needs them on the real filesystem, not inside a squashfs.

### Option 2 — Docker

#### 1. Install Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Run

```bash
./run.sh
```

`run.sh` does the same: it asks for your `sudo` password once, runs as root and
takes care of Docker for you — installing the engine (get.docker.com), the
`docker compose` plugin and starting the daemon if any of them is missing.

`run.sh` downloads the latest `.deb` from tonelib.net if it is missing, and
rebuilds the image only when the `.deb` changes (it compares the file's sha256
with an image label). To fetch a newer ToneLib release:

```bash
./run.sh --update
```

### Add to Menu

```bash
./install-desktop.sh
```

Creates entries for the AppImage (if built) and for Docker in
Menu → Sound & Video.

### Shared Folder

The entire ToneLib home directory `~/tonelib/` is used (Docker: mounted into the
container; AppImage: the app writes there natively), so files are the same
whichever way you run it.

**Useful directories:**
- `~/tonelib/` — backing tracks, IRs, NAM profiles, presets
- `~/tonelib/Music/GFX-Recordings/` — your recordings

```bash
cp ~/Downloads/*.mp3 ~/tonelib/          # add backing tracks
ls ~/tonelib/Music/GFX-Recordings/       # access recordings
```

### Audio Latency

#### 🎯 PulseAudio (default)
- **Latency:** ~10-20ms
- **Setup:** works out of the box (`PULSE_LATENCY_MSEC=20`)
- **Buffer:** 128-256 samples in ToneLib-GFX

#### ⚡ JACK (low latency)
- **Latency:** ~3-5ms
- **Setup:** install `jackd2` on the host and start it before the app
- **Docker:** the JACK socket and `/dev/shm` are already shared with the container

**Tips:** use a dedicated USB audio interface, close other audio apps, keep the
buffer at 128 samples.

### Troubleshooting

#### Terminal shows JACK / xprop messages

The app always probes JACK at startup and calls `xprop` looking for an
already-open window, so every launch prints lines like:

```
Cannot connect to server socket err = No such file or directory
jack server is not running or cannot be started
JackShmReadWritePtr::~JackShmReadWritePtr - Init not done for -1, skipping unlock
xprop: error: No window with name ToneLib GFX exists!
```

They are harmless — the window opens right after. This project does not filter
or suppress the app's output; if you want a quiet terminal, redirect it yourself
(`./ToneLib-GFX-amd64.AppImage 2>/dev/null`) or start a JACK server on the host.

#### Application doesn't open (Docker)
```bash
xhost +local:docker
```

#### AppImage won't mount
```bash
sudo apt install libfuse2t64            # Debian/Ubuntu 24.04
APPIMAGE_EXTRACT_AND_RUN=1 ./ToneLib-GFX-amd64.AppImage
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
~/tonelib/                      # ToneLib home (created on first run)
  ├── Music/
  │   └── GFX-Recordings/       # your recordings
  └── (backing tracks, IRs, NAM profiles, presets)

tonelib-docker/
├── Dockerfile                  # Ubuntu 24.04 image
├── compose.yml
├── entrypoint.sh               # container entrypoint
├── run.sh                      # Docker: download + build + run
├── build-appimage.sh           # AppImage: build from the .deb
├── install-desktop.sh          # menu entries
├── lib/root.sh                 # sudo elevation helper (script runs as root)
├── AGENTS.md                   # notes for AI/code agents
├── ToneLib-GFX-amd64.deb       # you add this (never committed)
└── ToneLib-GFX-amd64.AppImage  # generated by build-appimage.sh (ignored)
```

### Why Ubuntu 24.04?

The `.deb` cannot be installed with `dpkg -i` on anything newer than 22.04
because of its obsolete `Depends`. Since the binary is a static Qt5 build that
does not use those libraries, the image extracts the package
(`dpkg-deb -x`) instead of registering it, so a current LTS base works:
Ubuntu 24.04 (supported until 2029) with Mesa 24 and current ALSA/Pulse clients.

Verified on Ubuntu 24.04: the app opens, renders with GLX (llvmpipe works for
hosts without DRI) and enumerates audio devices.

### Releases and versioning

- The git tag (`vX.Y.Z`) is the version of **this packaging** (scripts, Docker
  image, AppImage builder) — not the ToneLib version.
- The ToneLib version comes from the `.deb` and appears in the release title and
  notes (example: tag `v1.0.0` for ToneLib 4.9.5).
- **No binaries are attached to releases.** ToneLib-GFX is proprietary; each
  user builds the AppImage locally from the official `.deb`.
- Every release is validated by CI: it downloads the `.deb`, runs
  `build-appimage.sh`, checks that the AppImage opens a window under Xvfb and
  builds the Docker image.

### Support the Project

If this project helped you, consider supporting its development:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/docg1701)

### License

MIT — for the Docker/AppImage configuration and scripts only.

ToneLib-GFX is property of ToneLib Team.

---

## Português

Execute o **ToneLib-GFX 4.9.5** em distribuições Linux modernas — como
**AppImage** standalone gerado localmente a partir do `.deb` oficial, ou dentro
de um container **Docker**.

### O Problema

O pacote `.deb` oficial declara dependências que não existem mais no
Ubuntu 22.04+/24.04, Linux Mint 21+, Debian 12+:

```
Package libgl1-mesa-glx is not installable
Package libcurl3-gnutls is not installable
Package libgcc1 is not installable
```

Por isso `dpkg -i ToneLib-GFX-amd64.deb` falha. O binário não usa nenhuma
dessas bibliotecas: ele traz **Qt5 estático** e carrega apenas `libc`, `libm`,
`libasound`, `libGL`, `libfontconfig` e `libfreetype` (o resto — X11,
`libcurl-gnutls`, `libjack` — é carregado com `dlopen` em tempo de execução).

### Aviso de licença

O ToneLib-GFX é proprietário. Este repositório **não distribui o `.deb`, o
AppImage nem qualquer binário da ToneLib** — só scripts e configuração. Você
baixa o `.deb` no site oficial e gera o AppImage localmente.

### Baixar o ToneLib-GFX

Baixe `ToneLib-GFX-amd64.deb` (Ubuntu 64-bit) no
[site oficial](https://tonelib.net/gfx-overview/) e coloque na raiz do
repositório.

```bash
git clone https://github.com/docg1701/tonelib-docker.git
cd tonelib-docker
mv ~/Downloads/ToneLib-GFX-amd64.deb .
```

### Opção 1 — AppImage (sem Docker)

Requisitos: x86_64, glibc ≥ 2.27 (qualquer distro de 2018 pra cá), X11 ou
XWayland, driver OpenGL funcionando, ALSA ou PulseAudio.

```bash
./build-appimage.sh          # --download baixa o .deb se ele não estiver aqui
./ToneLib-GFX-amd64.AppImage
```

Se você rodar como usuário normal, o script pede a senha do `sudo` e a partir daí
**roda como root**, instalando `squashfs-tools`/`curl` (`apt`/`dnf`/`pacman`) se
faltar. No final, os arquivos gerados são devolvidos ao seu usuário — nada de
arquivo com dono `root` no repositório. O AppImage usa o mesmo nome-base do
`.deb` (`ToneLib-GFX-amd64.AppImage`); a versão aparece na saída do script e na
entrada de desktop (`X-AppImage-Version`).

O `build-appimage.sh` descompacta o `.deb`, adiciona o wrapper `AppRun` e
empacota tudo num único executável (runtime + squashfs). No final ele mostra o
tamanho e o sha256 do arquivo.

O que vai dentro do AppImage: o binário do ToneLib, ícones e a entrada de
desktop. O que vem do host: glibc, X11/XWayland, driver OpenGL e a pilha de
áudio. Empacotar glibc, `libGL` ou `libX11` é justamente o que quebra AppImages,
então essas ficam no host (prática padrão).

Se não houver FUSE (containers, ou Ubuntu 24.04 sem `libfuse2t64`):

```bash
APPIMAGE_EXTRACT_AND_RUN=1 ./ToneLib-GFX-amd64.AppImage
```

Os plugins VST/VST3 do `.deb` **não** entram no AppImage — uma DAW precisa deles
no sistema de arquivos real, não dentro de um squashfs.

### Opção 2 — Docker

#### 1. Instalar Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker
```

#### 2. Executar

```bash
./run.sh
```

O `run.sh` faz o mesmo: pede a senha do `sudo` uma vez, roda como root e resolve
o Docker por você — instala o engine (get.docker.com), o plugin
`docker compose` e sobe o daemon se faltar algum.

O `run.sh` baixa o `.deb` mais recente do tonelib.net se ele não existir e
reconstrói a imagem só quando o `.deb` muda (compara o sha256 do arquivo com
uma label da imagem). Para pegar uma versão nova do ToneLib:

```bash
./run.sh --update
```

### Adicionar ao Menu

```bash
./install-desktop.sh
```

Cria entradas para o AppImage (se gerado) e para o Docker em
Menu → Som e Vídeo.

### Pasta Compartilhada

O diretório `~/tonelib/` é usado nos dois modos (Docker: montado no container;
AppImage: o app escreve direto), então os arquivos são os mesmos.

**Diretórios úteis:**
- `~/tonelib/` — backing tracks, IRs, perfis NAM, presets
- `~/tonelib/Music/GFX-Recordings/` — suas gravações

```bash
cp ~/Downloads/*.mp3 ~/tonelib/          # adicionar backing tracks
ls ~/tonelib/Music/GFX-Recordings/       # acessar gravações
```

### Latência de Áudio

#### 🎯 PulseAudio (padrão)
- **Latência:** ~10-20ms
- **Configuração:** funciona imediatamente (`PULSE_LATENCY_MSEC=20`)
- **Buffer:** 128-256 samples no ToneLib-GFX

#### ⚡ JACK (baixa latência)
- **Latência:** ~3-5ms
- **Configuração:** instale `jackd2` no host e inicie antes do app
- **Docker:** o socket JACK e `/dev/shm` já são compartilhados com o container

**Dicas:** use interface USB dedicada, feche outros apps de áudio, buffer de 128
samples.

### Troubleshooting

#### Terminal mostra mensagens de JACK / xprop

O app sempre testa o JACK na inicialização e chama `xprop` procurando uma janela
já aberta, então todo start imprime linhas como:

```
Cannot connect to server socket err = Arquivo ou diretório inexistente
jack server is not running or cannot be started
JackShmReadWritePtr::~JackShmReadWritePtr - Init not done for -1, skipping unlock
xprop: error: No window with name ToneLib GFX exists!
```

São inofensivas — a janela abre em seguida. Este projeto não filtra nem esconde
a saída do app; para um terminal silencioso, redirecione você mesmo
(`./ToneLib-GFX-amd64.AppImage 2>/dev/null`) ou suba um servidor JACK no host.

#### Aplicativo não abre (Docker)
```bash
xhost +local:docker
```

#### AppImage não monta
```bash
sudo apt install libfuse2t64            # Debian/Ubuntu 24.04
APPIMAGE_EXTRACT_AND_RUN=1 ./ToneLib-GFX-amd64.AppImage
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
~/tonelib/                      # diretório home do ToneLib (criado na 1ª execução)
  ├── Music/
  │   └── GFX-Recordings/       # suas gravações
  └── (backing tracks, IRs, perfis NAM, presets)

tonelib-docker/
├── Dockerfile                  # imagem Ubuntu 24.04
├── compose.yml
├── entrypoint.sh               # entrypoint do container
├── run.sh                      # Docker: baixar + buildar + rodar
├── build-appimage.sh           # AppImage: gera a partir do .deb
├── install-desktop.sh          # entradas no menu
├── lib/root.sh                 # elevação via sudo (script roda como root)
├── AGENTS.md                   # notas para agentes de IA/código
├── ToneLib-GFX-amd64.deb       # você adiciona (nunca commitado)
└── ToneLib-GFX-amd64.AppImage  # gerado por build-appimage.sh (ignorado)
```

### Por que Ubuntu 24.04?

O `.deb` não instala com `dpkg -i` em nada mais novo que 22.04 por causa do
`Depends` obsoleto. Como o binário é Qt5 estático e não usa essas libs, a imagem
extrai o pacote (`dpkg-deb -x`) em vez de registrá-lo — assim uma base LTS atual
funciona: Ubuntu 24.04 (suporte até 2029), Mesa 24 e clientes ALSA/Pulse atuais.

Verificado no Ubuntu 24.04: o app abre, renderiza via GLX (llvmpipe atende hosts
sem DRI) e enumera dispositivos de áudio.

### Releases e versionamento

- A tag git (`vX.Y.Z`) é a versão **deste empacotamento** (scripts, imagem
  Docker, gerador de AppImage) — não a versão do ToneLib.
- A versão do ToneLib vem do `.deb` e aparece no título e nas notas da release
  (exemplo: tag `v1.0.0` para o ToneLib 4.9.5).
- **Nenhum binário é anexado às releases.** O ToneLib-GFX é proprietário; cada
  usuário gera o AppImage localmente a partir do `.deb` oficial.
- Toda release é validada pelo CI: baixa o `.deb`, roda `build-appimage.sh`,
  confere que o AppImage abre janela no Xvfb e builda a imagem Docker.

### Apoie o Projeto

Se este projeto te ajudou, considere apoiar seu desenvolvimento:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/docg1701)

### Licença

MIT — apenas para os scripts e configuração de Docker/AppImage.

ToneLib-GFX é propriedade da ToneLib Team.

---

**Problemas?** Abra uma [issue](https://github.com/docg1701/tonelib-docker/issues).
