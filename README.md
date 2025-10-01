# ToneLib-GFX Docker

Container Docker para executar o **ToneLib-GFX** em sistemas Linux modernos (Ubuntu 22.04+, Linux Mint 21+, Debian 12+) que não possuem mais as dependências antigas necessárias.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Docker](https://img.shields.io/badge/docker-required-blue.svg)
![Platform](https://img.shields.io/badge/platform-linux-lightgrey.svg)

## 🎯 O Problema

O ToneLib-GFX é um excelente software de modelagem de amplificadores e efeitos para guitarra, mas seu pacote `.deb` oficial depende de bibliotecas antigas que foram descontinuadas em distribuições Linux modernas:

- `libcurl3-gnutls` → substituída por `libcurl4`
- `libgcc1` → substituída por `libgcc-s1`

Ao tentar instalar com `dpkg -i`, você recebe erros como:
```
dependency problems prevent configuration of tonelib-gfx:
 tonelib-gfx depends on libcurl3-gnutls; however:
  Package libcurl3-gnutls is not installed.
```

## 💡 A Solução

Este projeto fornece um ambiente Docker isolado baseado em **Ubuntu 20.04** (última versão LTS com as bibliotecas antigas) que permite executar o ToneLib-GFX nativamente, com:

✅ Interface gráfica completa (X11)
✅ Áudio via PulseAudio/ALSA
✅ Suporte a interfaces USB (Focusrite, Behringer, etc.)
✅ Persistência de configurações e presets
✅ Isolamento total do sistema host

## 📋 Pré-requisitos

### Software necessário:

- **Docker** (v20.10+)
- **Docker Compose** v2 (incluído no Docker Desktop ou via plugin)
- **Sistema X11** (presente por padrão na maioria das distros)
- **PulseAudio** (presente por padrão na maioria das distros)

### Instalar Docker (se ainda não tiver):

**Ubuntu/Mint/Debian:**
```bash
# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER

# Reiniciar sessão ou executar:
newgrp docker

# Verificar instalação
docker --version
docker compose version
```

**Outras distros:** Veja [documentação oficial do Docker](https://docs.docker.com/engine/install/)

## 🚀 Instalação

### Passo 1: Baixar o ToneLib-GFX

**IMPORTANTE:** Este repositório NÃO inclui o arquivo `.deb` do ToneLib-GFX por questões de licenciamento.

Baixe a versão mais recente do site oficial:
- 🔗 [ToneLib-GFX Download](https://tonelib.net/gfx-overview/)

Faça o download do pacote **"ToneLib-GFX-amd64.deb"** para Linux (64-bit).

### Passo 2: Clonar este repositório

```bash
git clone https://github.com/SEU_USUARIO/tonelib-docker.git
cd tonelib-docker
```

### Passo 3: Colocar o arquivo .deb no diretório

Mova o arquivo baixado para o diretório do projeto:

```bash
mv ~/Downloads/ToneLib-GFX-amd64.deb .
```

Sua estrutura deve ficar assim:
```
tonelib-docker/
├── Dockerfile
├── compose.yml
├── run.sh
├── install-desktop.sh
├── ToneLib-GFX-amd64.deb  ← Arquivo que você baixou
└── README.md
```

### Passo 4: Executar

```bash
./run.sh
```

Na primeira execução, o Docker irá:
1. Baixar a imagem base do Ubuntu 20.04
2. Instalar todas as dependências
3. Instalar o ToneLib-GFX
4. Construir a imagem (leva ~5 minutos)
5. Iniciar o aplicativo

Execuções subsequentes são instantâneas! 🚀

## 🖥️ Adicionar ao Menu de Aplicativos

Para adicionar um ícone no menu do Linux Mint, Ubuntu ou distros compatíveis:

```bash
./install-desktop.sh
```

Isso criará um atalho em:
- **Menu → Som e Vídeo → ToneLib GFX (Docker)**

Você também pode buscar por "ToneLib" no menu de aplicativos.

### Compatibilidade do ícone:

O script funciona em distribuições que seguem o padrão **XDG Desktop Entry**:
- ✅ Linux Mint (Cinnamon, MATE, XFCE)
- ✅ Ubuntu (GNOME, Unity)
- ✅ Debian (GNOME, KDE, XFCE)
- ✅ Pop!_OS
- ✅ Elementary OS
- ✅ Fedora
- ✅ Manjaro

### Desinstalar do menu:

```bash
rm ~/.local/share/applications/ToneLib-GFX-Docker.desktop
```

## 🎛️ Configuração de Áudio

### Interfaces USB

O container tem acesso automático a interfaces de áudio USB conectadas ao sistema:

```bash
# Verificar interfaces detectadas
docker compose run --rm tonelib-gfx cat /proc/asound/cards
```

### Configurar no ToneLib-GFX

1. Abra o ToneLib-GFX
2. Vá em **File → Preferences → Audio Settings**
3. Selecione sua interface de áudio
4. Ajuste buffer size (128 ou 256 samples para baixa latência)

### Troubleshooting de Áudio

**Sem som:**
```bash
# Verificar se PulseAudio está rodando
pulseaudio --check && echo "OK" || echo "PulseAudio não está rodando"

# Reiniciar PulseAudio
pulseaudio -k && pulseaudio --start
```

**Avisos ALSA sobre MIDI:**
```
ALSA lib seq_hw.c:466:(snd_seq_hw_open) open /dev/snd/seq failed: Permission denied
```
Estes avisos são normais e não afetam o funcionamento. São relacionados a portas MIDI.

## 📂 Pasta Compartilhada

O ToneLib-GFX tem acesso a uma pasta compartilhada entre o host e o container para facilitar o acesso a:

- 🎵 **Backing tracks**
- 🎸 **IRs (Impulse Responses)**
- 🎛️ **Presets**
- 📁 **Qualquer outro arquivo**

### Localização

**No seu sistema:** `~/ToneLib-Files/`

**Dentro do ToneLib-GFX:** `/home/tonelib/ToneLib-Files/`

### Como Usar

1. **Adicione seus arquivos** na pasta do host:
   ```bash
   # Copiar backing track
   cp ~/Downloads/backing-track.mp3 ~/ToneLib-Files/

   # Copiar IRs
   cp ~/Downloads/*.wav ~/ToneLib-Files/

   # Você pode criar subpastas se quiser organizar
   mkdir ~/ToneLib-Files/IRs
   cp ~/Downloads/*.wav ~/ToneLib-Files/IRs/
   ```

2. **No ToneLib-GFX**, ao importar arquivos, navegue até `/home/tonelib/ToneLib-Files`

3. **A pasta é criada automaticamente** na primeira execução do `run.sh`

### Dicas

- Organize como preferir (crie suas próprias subpastas)
- Arquivos aparecem instantaneamente - sem necessidade de reiniciar
- Funciona bidirecionalmente (host ↔ container)

### Mudar Localização (Opcional)

Edite o `compose.yml`:

```yaml
volumes:
  # Trocar ~/ToneLib-Files pela pasta desejada
  - ${HOME}/Música/ToneLib:/home/tonelib/ToneLib-Files:rw
```

## 💾 Dados Persistentes

Suas configurações, presets e IRs são salvos automaticamente em volumes Docker persistentes.

### Backup

```bash
# Criar backup
docker run --rm \
  -v tonelib-docker_tonelib-config:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/tonelib-backup-$(date +%Y%m%d).tar.gz -C /data .

# Restaurar backup
docker run --rm \
  -v tonelib-docker_tonelib-config:/data \
  -v $(pwd):/backup \
  ubuntu tar xzf /backup/tonelib-backup-YYYYMMDD.tar.gz -C /data
```

### Listar volumes

```bash
docker volume ls | grep tonelib
```

### Limpar dados (reset completo)

```bash
docker compose down
docker volume rm tonelib-docker_tonelib-config tonelib-docker_tonelib-data
```

## 🐛 Troubleshooting

### Aplicativo não abre / Tela preta

```bash
# Permitir conexões X11
xhost +local:docker

# Verificar DISPLAY
echo $DISPLAY  # Deve mostrar :0 ou :1
```

### Popups com ruído colorido

Já corrigido! O compose.yml inclui:
- `ipc: host` (compartilha IPC para transparências)
- `shm_size: 256mb` (memória compartilhada aumentada)

### Reconstruir imagem

```bash
docker compose down
docker rmi tonelib-gfx:latest
docker compose build --no-cache
```

### Permissões de áudio

Se não conseguir acessar interface USB:

```bash
# Verificar se seu usuário está no grupo audio
groups | grep audio

# Se não estiver, adicionar:
sudo usermod -aG audio $USER
# Depois fazer logout/login
```

## 🔧 Uso Avançado

### Executar sem o script

```bash
xhost +local:docker
export USER_ID=$(id -u) GROUP_ID=$(id -g)
docker compose up
# Pressione Ctrl+C para sair
xhost -local:docker
```

### Modo interativo (debug)

```bash
docker compose run --rm tonelib-gfx /bin/bash
```

### Verificar dependências

```bash
docker compose run --rm tonelib-gfx ldd /usr/bin/ToneLib-GFX
```

## 📁 Estrutura do Projeto

```
tonelib-docker/
├── Dockerfile                    # Imagem base Ubuntu 20.04 + dependências
├── compose.yml                   # Configuração Docker Compose
├── run.sh                        # Script principal de execução
├── install-desktop.sh            # Instalador de ícone do menu
├── .dockerignore                 # Arquivos ignorados no build
├── .gitignore                    # Git ignore
├── LICENSE                       # Licença MIT
├── CONTRIBUTING.md               # Guia para contribuidores
├── tonelib-icon.png              # Ícone extraído do .deb
├── ToneLib-GFX-Docker.desktop    # Arquivo .desktop
└── README.md                     # Esta documentação
```

**Você precisa adicionar:**
- `ToneLib-GFX-amd64.deb` (baixado do site oficial)

**Criado automaticamente na primeira execução:**
- `~/ToneLib-Files/` - Pasta compartilhada para backing tracks, IRs, etc.

## 🔒 Segurança

- ✅ Container roda com usuário **não-root** (mesmo UID/GID do host)
- ✅ Sem modo `--privileged`
- ✅ Acesso limitado a `/dev/snd` (áudio) e `/dev/dri` (GPU)
- ✅ Permissões X11 restritas a `local:docker`
- ✅ Volumes isolados do sistema host

## 📝 Notas Técnicas

### Por que Ubuntu 20.04?

Ubuntu 20.04 LTS é a última versão oficial que mantém `libcurl3-gnutls` nos repositórios. Versões posteriores (22.04+) a removeram completamente.

### Alternativas avaliadas

| Solução | Status | Motivo |
|---------|--------|--------|
| Instalar libcurl3 de repos antigos | ❌ | Conflitos de dependências |
| Criar symlink libcurl4 → libcurl3 | ❌ | ABI incompatível, crashes |
| Snap/Flatpak | ❌ | ToneLib-GFX não disponível |
| AppImage | ❌ | Não fornecido oficialmente |
| **Docker + Ubuntu 20.04** | ✅ | **Funciona perfeitamente** |

### Overhead de performance

Praticamente **zero**! O Docker roda aplicações nativas (não é VM):
- Latência de áudio: idêntica ao host
- Uso de CPU/RAM: idêntico ao host
- Acesso direto à GPU para renderização

## 🤝 Contribuindo

Contribuições são bem-vindas! Se você encontrar problemas ou tiver sugestões:

1. Abra uma [issue](https://github.com/SEU_USUARIO/tonelib-docker/issues)
2. Envie um Pull Request

### Testado em:

- [x] Linux Mint 21.3 (Cinnamon)
- [ ] Ubuntu 22.04
- [ ] Ubuntu 24.04
- [ ] Debian 12
- [ ] Pop!_OS 22.04

Testou em outra distro? Abra um PR adicionando na lista!

## 📚 Recursos

- [Site Oficial ToneLib-GFX](https://tonelib.net/gfx-overview/)
- [Documentação Docker](https://docs.docker.com/)
- [X11 em containers](https://wiki.ros.org/docker/Tutorials/GUI)
- [PulseAudio em containers](https://github.com/mviereck/x11docker/wiki/Container-sound:-ALSA-or-Pulseaudio)

## 📜 Licença

Este projeto (arquivos de configuração Docker) está sob licença MIT.

**ToneLib-GFX** é propriedade da ToneLib Team e deve ser baixado do site oficial. Este projeto não distribui ou modifica o software original.

## ⭐ Agradecimentos

- **ToneLib Team** pelo excelente software
- Comunidade Docker por toda documentação
- Todos que reportaram issues e contribuíram

---

**Curtiu?** Deixe uma ⭐ no repositório!

**Problemas?** Abra uma [issue](https://github.com/SEU_USUARIO/tonelib-docker/issues)!

**Funciona para você?** Compartilhe com outros guitarristas! 🎸
