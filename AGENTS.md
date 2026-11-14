# AGENTS.md

Instruções para agentes de IA (e humanos) que forem mexer neste repositório.

## O que é este repositório

Scripts e configuração para rodar o **ToneLib-GFX** (software proprietário de
simulação de amplificadores) em Linux moderno, de duas formas:

1. **AppImage** gerado localmente por `build-appimage.sh` a partir do `.deb` oficial.
2. **Container Docker** (`Dockerfile` + `compose.yml` + `run.sh`) baseado em Ubuntu 24.04.

O repositório **não contém binários da ToneLib**.

## Regras invioláveis

- **Nunca commite** `ToneLib-GFX-amd64.deb`, `*.AppImage`, `build/` ou `.cache/`.
  São binários proprietários da ToneLib; a licença não permite redistribuição.
  O `.gitignore` já cobre todos eles — não o contorne.
- **Nunca modifique o binário do ToneLib** (nem patcheie, nem repacke com
  alterações). O projeto só empacota.
- **Não adicione dependências desnecessárias** ao Dockerfile (ver seção seguinte:
  a maior parte das libs gráficas é inútil aqui).
- Documentação é **bilíngue**: toda mudança de comportamento vai no `README.md`
  em inglês **e** em português.

## Fatos verificados sobre o binário (4.9.5, nov/2026)

Checados com `readelf`/parse de ELF e teste real em rootfs Ubuntu 24.04:

- `usr/bin/ToneLib-GFX` tem **Qt5, libstdc++ e libgcc estáticos**.
- `DT_NEEDED`: `libc.so.6`, `libm.so.6`, `libdl.so.2`, `libpthread.so.0`,
  `libasound.so.2`, `libfontconfig.so.1`, `libfreetype.so.6`, `libGL.so.1`.
- Carregadas via `dlopen`: `libX11`, `libXext`, `libXinerama`, `libXcursor`,
  `libXrandr`, `libXrender`, `libXss`, `libcurl-gnutls.so.4` (ou `libcurl.so.4`),
  `libjack.so.0`.
- Versão máxima de glibc exigida: **2.27** (`GLIBC_2.18` em libc, `GLIBC_2.27`
  em libm) → qualquer distro de 2018 em diante.
- Versão máxima de ALSA exigida: `ALSA_0.9.0rc4`.
- `qtbase5-dev`, `libqt5*`, `libgtk-3-0`, `jackd2`, `qjackctl`,
  `pulseaudio-module-jack` e `a2jmidid` **não são necessários** — foram removidos
  do Dockerfile; o app tem Qt próprio e só precisa do cliente JACK (`libjack-jackd2-0`).

## O `Depends` do .deb é obsoleto

O control do pacote declara `libgl1-mesa-glx`, `libcurl3-gnutls`, `libgcc1` e
`libasound2`. Nenhum desses nomes resolve no Ubuntu 24.04 (`libgcc1` virou
`libgcc-s1`, `libasound2` virou `libasound2t64`, `libcurl3-gnutls` virou
`libcurl3t64-gnutls`, `libgl1-mesa-glx` não existe mais). Por isso:

- Dockerfile usa `dpkg-deb -x` (extrai os arquivos) em vez de `dpkg -i`.
- `build-appimage.sh` também só extrai; nada de resolver dependência do dpkg.

Se um dia a ToneLib publicar um `.deb` com `Depends` correto, dá para simplificar
os dois caminhos — confira o control antes.

## Como testar

```bash
# Docker
docker compose build
docker compose run --rm tonelib-gfx aplay -l   # container sobe?

# AppImage (precisa de um .deb local)
./build-appimage.sh
./ToneLib-GFX-*-x86_64.AppImage                # precisa de X11/XWayland
APPIMAGE_EXTRACT_AND_RUN=1 ./ToneLib-GFX-*.AppImage   # sem FUSE

# Smoke test sem GUI (útil em CI/headless): Xvfb + xwininfo
Xvfb :99 -screen 0 1280x800x24 & DISPLAY=:99 ./ToneLib-GFX-*.AppImage &
DISPLAY=:99 xwininfo -root -tree | grep 'ToneLib GFX'
```

Sintoma clássico em teste headless: `Xvfb` que não sobe por causa de
`/tmp/.X99-lock` antigo — o app então sai com código 1 sem mensagem clara.
Remova o lock (`rm -f /tmp/.X99-lock /tmp/.X11-unix/X99`) antes de concluir que
o empacotamento está quebrado.

## Mapa dos arquivos

| Arquivo | Papel |
| --- | --- |
| `Dockerfile` | imagem Ubuntu 24.04, extrai o `.deb`, UID/GID do host, healthcheck |
| `compose.yml` | X11, PulseAudio, `/dev/snd`, `/dev/dri`, volumes de config |
| `entrypoint.sh` | env de áudio/Qt e `exec /usr/bin/ToneLib-GFX` dentro do container |
| `run.sh` | baixa/valida o `.deb`, reconstrói se o sha256 mudou, sobe o compose |
| `build-appimage.sh` | `.deb` → AppDir → runtime pinado + squashfs → AppImage |
| `install-desktop.sh` | gera entradas `.desktop` para AppImage e Docker |
| `.github/workflows/release.yml` | em tag `v*`: baixa o `.deb`, gera AppImage, publica release |

## Release

```bash
git tag v4.9.5
git push origin v4.9.5
```

A workflow baixa o `.deb` mais recente do tonelib.net, roda `build-appimage.sh`,
valida o build com um smoke test headless (Xvfb + xwininfo) e cria a release com
as instruções de uso. **Ela falha** se a versão do pacote não bater com a tag.

Nenhum binário é anexado à release nem commitado: o `.deb` e o AppImage são
propriedade da ToneLib e cada usuário gera o seu localmente.

## Estilo

- Scripts: `#!/bin/bash`, `set -e` (ou `set -euo pipefail`), mensagens claras,
  falhar alto em vez de adivinhar.
- Comentários e documentação em português; nomes de variáveis/funções em inglês.
- Commits curtos, em português, no imperativo ("Atualiza base para Ubuntu 24.04").
