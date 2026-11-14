#!/bin/bash
# Elevação de privilégios dos scripts deste repositório.
#
# Padrão: se o script não estiver rodando como root, ele se re-executa com
# `sudo` — o terminal pede a senha uma vez e, a partir daí, todo o script roda
# como root. Nada de imprimir comando para o usuário copiar.
#
# O contexto de quem chamou (usuário, home, uid, gid, DISPLAY) é passado como
# argumento para a instância root, porque `sudo` reseta HOME e pode descartar
# DISPLAY.

# Lê os --as-* (quando já é a instância root) ou captura o ambiente atual, e
# deixa os argumentos do usuário em SCRIPT_ARGS.
parse_sudo_context() {
    ORIG_USER=$(id -un)
    ORIG_HOME=${HOME:-/root}
    ORIG_UID=$(id -u)
    ORIG_GID=$(id -g)
    ORIG_DISPLAY=${DISPLAY:-}

    while [ $# -gt 0 ]; do
        case "$1" in
            --as-user) ORIG_USER="$2"; shift 2 ;;
            --as-home) ORIG_HOME="$2"; shift 2 ;;
            --as-uid) ORIG_UID="$2"; shift 2 ;;
            --as-gid) ORIG_GID="$2"; shift 2 ;;
            --as-display) ORIG_DISPLAY="$2"; shift 2 ;;
            *) break ;;
        esac
    done
    SCRIPT_ARGS=("$@")

    export ORIG_USER ORIG_HOME ORIG_UID ORIG_GID ORIG_DISPLAY

    if [ "$(id -u)" -eq 0 ]; then
        # root não tem cookie do X da sessão do usuário
        if [ -z "${XAUTHORITY:-}" ] && [ -n "$ORIG_HOME" ] && [ -f "$ORIG_HOME/.Xauthority" ]; then
            export XAUTHORITY="$ORIG_HOME/.Xauthority"
        fi
    fi
    [ -n "$ORIG_DISPLAY" ] && export DISPLAY="$ORIG_DISPLAY"

    return 0
}

# Re-executa o script com sudo se ainda não for root.
# Uso: ensure_root <caminho-do-script> [args do usuário...]
ensure_root() {
    local script="$1"
    shift

    [ "$(id -u)" -eq 0 ] && return 0

    if ! command -v sudo > /dev/null 2>&1; then
        echo "[ERRO] sudo não encontrado. Rode como root: su -c '$script'" >&2
        exit 1
    fi

    echo "[SUDO] Pedindo a senha para rodar o script como root..."
    exec sudo -- "$script" \
        --as-user "$ORIG_USER" \
        --as-home "$ORIG_HOME" \
        --as-uid "$ORIG_UID" \
        --as-gid "$ORIG_GID" \
        --as-display "$ORIG_DISPLAY" \
        "$@"
}

# Detecta o gerenciador de pacotes da distro
detect_pm() {
    local pm
    for pm in apt-get dnf pacman zypper apk; do
        if command -v "$pm" > /dev/null 2>&1; then
            echo "$pm"
            return 0
        fi
    done
    return 1
}

# Nome do pacote por gerenciador (só os casos que mudam de nome)
pkg_for() {
    local name="$1" pm="$2"

    case "$name" in
        xz)
            case "$pm" in
                apt-get) echo "xz-utils" ;;
                *) echo "xz" ;;
            esac
            ;;
        *) echo "$name" ;;
    esac
}

# Instala um pacote (o script já está root neste ponto)
pm_install() {
    local pkg="$1" pm

    if ! pm=$(detect_pm); then
        echo "[ERRO] Nenhum gerenciador de pacotes conhecido; instale '$pkg' manualmente." >&2
        return 1
    fi

    pkg=$(pkg_for "$pkg" "$pm")
    echo "[INFO] Instalando pacote '$pkg' ($pm)..."
    case "$pm" in
        apt-get)
            apt-get update > /dev/null 2>&1 || true
            apt-get install -y "$pkg"
            ;;
        dnf) dnf install -y "$pkg" ;;
        pacman) pacman -S --noconfirm "$pkg" ;;
        zypper) zypper install -y "$pkg" ;;
        apk) apk add "$pkg" ;;
    esac
}

# Garante que um binário existe; instala o pacote se faltar.
# Uso: require_tool <binário> <pacote>
require_tool() {
    local bin="$1" pkg="$2"

    command -v "$bin" > /dev/null 2>&1 && return 0

    echo "[INFO] '$bin' não encontrado (pacote '$pkg')."
    pm_install "$pkg" || {
        echo "[ERRO] '$bin' continua indisponível." >&2
        return 1
    }

    command -v "$bin" > /dev/null 2>&1 || {
        echo "[ERRO] '$bin' não apareceu no PATH depois da instalação." >&2
        return 1
    }
    return 0
}

# Devolve a posse de um arquivo/diretório ao usuário que chamou o script.
# Uso: give_back <caminho...>
give_back() {
    [ "$ORIG_UID" = "0" ] && return 0
    chown -R "$ORIG_UID:$ORIG_GID" "$@" 2> /dev/null || true
}
